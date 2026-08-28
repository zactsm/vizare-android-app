const { createClient } = require('@supabase/supabase-js');

const MAX_BODY_SIZE = 1024 * 1024; // 1 MB payload limit

// In-memory sliding window rate limiter
const rateLimitMap = new Map();
function checkRateLimit(key, maxAttempts, windowMs) {
  const now = Date.now();
  const records = rateLimitMap.get(key) || [];
  const validRecords = records.filter(ts => now - ts < windowMs);
  if (validRecords.length >= maxAttempts) {
    return false;
  }
  validRecords.push(now);
  rateLimitMap.set(key, validRecords);
  return true;
}

function validatePasswordStrength(password) {
  if (typeof password !== 'string' || password.length < 8) {
    return 'Password must be at least 8 characters long.';
  }
  if (!/[A-Z]/.test(password)) {
    return 'Password must contain at least one uppercase letter (A-Z).';
  }
  if (!/[a-z]/.test(password)) {
    return 'Password must contain at least one lowercase letter (a-z).';
  }
  if (!/[0-9]/.test(password)) {
    return 'Password must contain at least one number (0-9).';
  }
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    return 'Password must contain at least one special character (!@#$%...).';
  }
  return null;
}

function corsHeaders(request) {
  const origin = (request && request.headers && request.headers.origin) ? request.headers.origin : '';
  const rawAllowed = process.env.ALLOWED_ORIGINS || 'https://vizare.app,https://vizare-web.vercel.app,https://vizare-app.vercel.app,http://localhost:3000';
  const allowedOrigins = rawAllowed
    .split(',')
    .map((s) => s.trim().replace(/\/+$/, ''))
    .filter(Boolean);

  let allowOrigin = '';
  if (origin) {
    const normalized = origin.trim().replace(/\/+$/, '');
    if (allowedOrigins.includes(normalized)) {
      allowOrigin = origin;
    } else {
      try {
        const parsed = new URL(normalized);
        if (
          parsed.hostname === 'localhost' ||
          parsed.hostname === '127.0.0.1' ||
          parsed.hostname === 'vizare.app' ||
          parsed.hostname.endsWith('.vizare.app') ||
          parsed.hostname.endsWith('.vercel.app')
        ) {
          allowOrigin = origin;
        } else {
          allowOrigin = origin;
        }
      } catch (_) {
        allowOrigin = origin;
      }
    }
  } else {
    allowOrigin = '*';
  }

  const requestedHeaders =
    (request && request.headers && (request.headers['access-control-request-headers'] || request.headers['Access-Control-Request-Headers'])) || '';
  const defaultHeaders =
    'Content-Type, Authorization, X-Requested-With, Accept, Origin, apikey, X-Client-Info, Range, Prefer, Cache-Control, Pragma';
  const allowHeaders = requestedHeaders
    ? `${requestedHeaders}, ${defaultHeaders}`
    : defaultHeaders;

  return {
    ...(allowOrigin ? { 'Access-Control-Allow-Origin': allowOrigin } : {}),
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': allowHeaders,
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'SAMEORIGIN',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(self), payment=(), usb=(), display-capture=(), screen-wake-lock=(self), accelerometer=(self "https://sketchfab.com"), gyroscope=(self "https://sketchfab.com"), xr-spatial-tracking=(self "https://sketchfab.com")',
    'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' wasm-unsafe-eval https://ajax.googleapis.com https://maps.googleapis.com https://www.gstatic.com https://*.gstatic.com https://accounts.google.com blob:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' data: https://fonts.gstatic.com https://fonts.googleapis.com; img-src 'self' data: blob: https:; connect-src 'self' data: blob: https://*.supabase.co wss://*.supabase.co https://maps.googleapis.com https://fonts.googleapis.com https://fonts.gstatic.com https://www.gstatic.com https://*.gstatic.com https://ajax.googleapis.com https://accounts.google.com https://*.googleapis.com https://*.vercel.app https://vizare.app https://*.vizare.app https://vercel.app https://sketchfab.com https://*.sketchfab.com https://api.emailjs.com http://localhost:* http://127.0.0.1:* ws://localhost:* ws://127.0.0.1:*; media-src 'self' data: blob: https:; frame-src 'self' https://accounts.google.com https://sketchfab.com https://*.sketchfab.com https://maps.googleapis.com https://*.google.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self';",
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw Object.assign(
      new Error(`Missing required environment variable: ${name}`),
      { code: 'SERVER_CONFIGURATION_ERROR' },
    );
  }
  return value;
}

function createClients() {
  const url = requiredEnv('SUPABASE_URL');
  const publishableKey = requiredEnv('SUPABASE_PUBLISHABLE_KEY');
  const secretKey = requiredEnv('SUPABASE_SECRET_KEY');
  const options = { auth: { autoRefreshToken: false, persistSession: false } };
  const publicClient = createClient(url, publishableKey, options);
  const admin = createClient(url, secretKey, options);
  return {
    admin,
    publicClient,
  };
}

function createUserClient(token) {
  if (!token) return null;
  const url = requiredEnv('SUPABASE_URL');
  const publishableKey = requiredEnv('SUPABASE_PUBLISHABLE_KEY');
  return createClient(url, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
}

function routeName(request) {
  return new URL(request.url, 'http://localhost').pathname
    .replace(/^\/api\/?/, '')
    .replace(/\/$/, '');
}

function query(request) {
  return Object.fromEntries(
    new URL(request.url, 'http://localhost').searchParams,
  );
}

async function readBody(request) {
  if (request.body && typeof request.body === 'object') return request.body;
  if (typeof request.body === 'string') {
    return parseBody(request.body, request.headers['content-type']);
  }

  const raw = await new Promise((resolve, reject) => {
    let data = '';
    let totalSize = 0;
    request.on('data', (chunk) => {
      totalSize += chunk.length;
      if (totalSize > MAX_BODY_SIZE) {
        request.destroy(Object.assign(new Error('Payload Too Large'), { code: 'PAYLOAD_TOO_LARGE' }));
        return;
      }
      data += chunk;
    });
    request.on('end', () => resolve(data));
    request.on('error', reject);
  });
  return parseBody(raw, request.headers['content-type']);
}

function parseBody(raw, contentType = '') {
  if (!raw) return {};
  if (contentType.includes('application/json')) return JSON.parse(raw);
  return Object.fromEntries(new URLSearchParams(raw));
}

function propertyJson(property) {
  return {
    ...property,
    is_featured: property.is_featured ? 1 : 0,
    property_type: property.property_type || 'Modern Luxury',
  };
}

function failOn(error) {
  if (error) throw error;
}

async function getAuthUser(request, publicClient) {
  const authorization = request.headers.authorization || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice(7)
    : '';
  if (!token) return null;
  const result = await publicClient.auth.getUser(token);
  return result.error ? null : result.data.user;
}

async function profileForUser(client, user) {
  if (!client || !user) return null;
  try {
    let result = await client
      .from('profiles')
      .select('*')
      .eq('auth_user_id', user.id)
      .maybeSingle();
    if (result.error) {
      if (result.error.code === '42501' || result.error.code === 'PGRST116') {
        return null;
      }
      failOn(result.error);
    }

    // Only link records imported from the old database if the email has been confirmed
    const isEmailVerified = Boolean(
      user.email_confirmed_at ||
      user.confirmed_at ||
      user.app_metadata?.provider === 'google'
    );

    if (!result.data && user.email && isEmailVerified) {
      try {
        result = await client
          .from('profiles')
          .update({ auth_user_id: user.id })
          .eq('email', user.email)
          .is('auth_user_id', null)
          .select('*')
          .maybeSingle();
        if (!result.error && result.data) {
          return result.data;
        }
      } catch (_) {}
    }
    return result.data;
  } catch (_) {
    return null;
  }
}

async function requireProfile(request, admin, publicClient) {
  const authorization = request.headers.authorization || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice(7)
    : '';
  const user = await getAuthUser(request, publicClient);
  if (!user) throw Object.assign(new Error('Authentication required.'), { status: 401 });

  const userClient = createUserClient(token);
  let profile = await profileForUser(admin, user);
  if (!profile && userClient) {
    profile = await profileForUser(userClient, user);
  }
  if (!profile) {
    profile = await ensureProfile(admin, user, {}, userClient);
  }
  if (!profile || !profile.is_active) {
    throw Object.assign(new Error('Account is unavailable.'), { status: 403 });
  }
  return { user, profile };
}

async function ensureProfile(admin, user, values = {}, userClient = null) {
  const clients = [];
  if (admin) clients.push(admin);
  if (userClient) clients.push(userClient);

  for (const client of clients) {
    try {
      const existing = await profileForUser(client, user);
      if (existing) return existing;
    } catch (_) {}
  }

  const metadata = user.user_metadata || {};
  const insertPayload = {
    auth_user_id: user.id,
    email: user.email,
    full_name:
      values.full_name || metadata.full_name || metadata.name || 'User',
    role: values.role || metadata.role || 'homebuyer',
    has_password:
      values.has_password !== undefined
        ? values.has_password
        : metadata.has_password === true,
    is_active: true,
  };

  for (const client of clients) {
    try {
      const result = await client
        .from('profiles')
        .insert(insertPayload)
        .select('*')
        .maybeSingle();
      if (!result.error && result.data) return result.data;
    } catch (_) {}
  }

  // Safe in-memory profile fallback
  return {
    id: 0,
    auth_user_id: user.id,
    email: user.email,
    full_name: insertPayload.full_name,
    role: insertPayload.role,
    has_password: insertPayload.has_password,
    is_active: true,
    created_at: new Date().toISOString(),
  };
}

function authPayload(session, profile, extra = {}) {
  return {
    message: 'Login successful.',
    user_type: profile.role,
    has_password: profile.has_password,
    access_token: session?.access_token || null,
    refresh_token: session?.refresh_token || null,
    ...extra,
  };
}

async function assertPropertyOwner(admin, profile, propertyId) {
  const result = await admin
    .from('properties')
    .select('id,homeowner_id')
    .eq('id', propertyId)
    .single();
  failOn(result.error);
  if (profile.role !== 'admin' && result.data.homeowner_id !== profile.id) {
    throw Object.assign(new Error('You cannot modify this property.'), {
      status: 403,
    });
  }
}

async function assertConversationParticipant(admin, profile, conversationId) {
  const convRes = await admin
    .from('conversations')
    .select('id, buyer_id, homeowner_id')
    .eq('id', conversationId)
    .maybeSingle();
  failOn(convRes.error);
  if (!convRes.data) {
    throw Object.assign(new Error('Conversation not found.'), {
      status: 404,
    });
  }
  if (
    profile.role !== 'admin' &&
    convRes.data.buyer_id !== profile.id &&
    convRes.data.homeowner_id !== profile.id
  ) {
    throw Object.assign(new Error('You are not authorized to access this conversation.'), {
      status: 403,
    });
  }
  return convRes.data;
}

async function dispatch(name, request, admin, publicClient) {
  const input = request.method === 'GET' ? query(request) : await readBody(request);
  const clientIp = request.headers['x-forwarded-for'] || request.socket?.remoteAddress || 'unknown';

  if (name === 'create_account.php') {
    if (!checkRateLimit(`create_${clientIp}`, 10, 3600000)) {
      return [429, { message: 'Too many account creation attempts. Please try again later.' }];
    }

    const role =
      String(input.isHomeBuyer).toLowerCase() === 'true'
        ? 'homebuyer'
        : 'homeowner';
    const email = String(input.email || '').trim().toLowerCase();
    const password = String(input.password || '');
    const fullName = String(input.name || '').trim();
    if (!email || !password || !fullName) {
      return [400, { message: 'Name, email, and password are required.' }];
    }
    const passwordError = validatePasswordStrength(password);
    if (passwordError) {
      return [400, { message: passwordError }];
    }

    const result = await publicClient.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role,
          has_password: true,
        },
      },
    });

    if (result.error) {
      if (
        result.error.message?.toLowerCase().includes('already exists') ||
        result.error.message?.toLowerCase().includes('already registered') ||
        result.error.status === 422 ||
        result.error.status === 409
      ) {
        return [409, { message: 'An account with this email already exists. Please log in.' }];
      }
      if (result.error.status === 429 || result.error.message?.toLowerCase().includes('rate limit')) {
        return [429, { message: 'Rate limit reached. Please wait a few minutes before trying again.' }];
      }
      let errorMsg = result.error.message;
      if (!errorMsg || errorMsg === '{}' || errorMsg.trim() === '') {
        errorMsg = 'Failed to send confirmation email. Please check your network connection and try again.';
      }
      return [result.error.status || 400, { message: errorMsg }];
    }

    if (!result.data.user || result.data.user.identities?.length === 0) {
      return [409, { message: 'An account with this email already exists. Please log in.' }];
    }

    const user = result.data.user;
    const session = result.data.session;
    const token = session?.access_token;
    const userClient = createUserClient(token);

    let profile = null;
    try {
      profile = await ensureProfile(admin, user, {
        full_name: fullName,
        role,
        has_password: true,
        consent_terms_at: new Date().toISOString(),
        consent_privacy_at: new Date().toISOString(),
        consent_version: 'v1.0',
      }, userClient);
    } catch (profileErr) {
      console.warn('Profile creation note on signup:', profileErr?.message);
    }

    return [
      200,
      {
        message: session
          ? 'Account created successfully.'
          : 'Account created successfully! Please check your email to verify your account before logging in.',
        requires_email_confirmation: !session,
        user_type: profile?.role || role,
        has_password: true,
        access_token: session?.access_token || null,
        refresh_token: session?.refresh_token || null,
      },
    ];
  }

  if (name === 'login.php') {
    const email = String(input.email || '').trim().toLowerCase();
    if (!checkRateLimit(`login_${clientIp}_${email}`, 10, 300000)) {
      return [429, { message: 'Too many login attempts. Please try again in a few minutes.' }];
    }
    const result = await publicClient.auth.signInWithPassword({
      email,
      password: String(input.password || ''),
    });
    if (result.error) {
      const errMsg = (result.error.message || '').toLowerCase();
      const errCode = (result.error.code || '').toLowerCase();
      if (
        errMsg.includes('email not confirmed') ||
        errMsg.includes('email address not verified') ||
        errCode === 'email_not_confirmed'
      ) {
        return [
          403,
          {
            message: 'Your email address has not been verified yet. Please check your inbox or resend the verification email.',
            requires_email_confirmation: true,
            email,
          },
        ];
      }
      return [401, { message: 'Invalid email or password.' }];
    }
    const token = result.data.session?.access_token;
    const userClient = createUserClient(token);
    const profile = await ensureProfile(admin, result.data.user, {}, userClient);
    if (!profile.is_active) {
      return [403, { message: 'This account has been deactivated.' }];
    }
    return [200, authPayload(result.data.session, profile)];
  }

  if (name === 'resend_verification.php') {
    const email = String(input.email || '').trim().toLowerCase();
    if (!email) {
      return [400, { message: 'Email is required.' }];
    }
    if (!checkRateLimit(`resend_${clientIp}_${email}`, 3, 300000)) {
      return [429, { message: 'Too many resend attempts. Please wait a few minutes before trying again.' }];
    }
    const res = await publicClient.auth.resend({
      type: 'signup',
      email,
    });
    if (res.error) {
      if (res.error.status === 429 || res.error.message?.toLowerCase().includes('rate limit')) {
        return [429, { message: 'Rate limit reached. Please wait a few minutes before requesting another email.' }];
      }
      return [res.error.status || 400, { message: res.error.message }];
    }
    return [200, { message: 'Verification email sent. Please check your inbox or spam folder.' }];
  }

  if (name === 'forgot_password.php') {
    const email = String(input.email || '').trim().toLowerCase();
    if (!email) {
      return [400, { message: 'Email address is required.' }];
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return [400, { message: 'Please enter a valid email address.' }];
    }
    if (!checkRateLimit(`forgot_pw_${clientIp}_${email}`, 3, 300000)) {
      return [429, { message: 'Too many password reset requests. Please wait a few minutes before trying again.' }];
    }
    const res = await publicClient.auth.resetPasswordForEmail(email);
    if (res.error) {
      if (res.error.status === 429 || res.error.message?.toLowerCase().includes('rate limit')) {
        return [429, { message: 'Rate limit reached. Please wait a few minutes before trying again.' }];
      }
      return [res.error.status || 400, { message: res.error.message }];
    }
    return [200, { success: true, message: 'Password reset link has been sent to your email.' }];
  }

  if (name === 'get_all_listings.php') {
    const result = await admin
      .from('properties')
      .select('*')
      .eq('status', 'approved')
      .order('created_at', { ascending: false });
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'get_property_types.php') {
    const result = await admin
      .from('property_types')
      .select('*')
      .order('name', { ascending: true });
    failOn(result.error);
    return [200, result.data || []];
  }

  if (name === 'search_properties.php') {
    const rawTerm = String(input.term || '').trim().slice(0, 100);
    const term = rawTerm.replace(/[^a-zA-Z0-9\s-]/g, '').replace(/\s+/g, ' ');
    let builder = admin
      .from('properties')
      .select('*')
      .eq('status', 'approved')
      .order('created_at', { ascending: false });
    if (term) {
      builder = builder.or(
        `name.ilike.%${term}%,location.ilike.%${term}%,property_type.ilike.%${term}%,description.ilike.%${term}%`,
      );
    }
    const result = await builder;
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'get_property_images.php') {
    const propId = Number(input.property_id);
    if (!propId) {
      return [400, { message: 'Invalid property ID.' }];
    }
    const propCheck = await admin
      .from('properties')
      .select('id,status,homeowner_id')
      .eq('id', propId)
      .maybeSingle();
    failOn(propCheck.error);
    if (!propCheck.data) {
      return [404, { message: 'Property not found.' }];
    }
    if (propCheck.data.status !== 'approved') {
      const authUser = await getAuthUser(request, publicClient);
      if (!authUser) return [404, { message: 'Property not found.' }];
      const callerProfile = await profileForUser(admin, authUser);
      if (
        !callerProfile ||
        (callerProfile.role !== 'admin' && callerProfile.id !== propCheck.data.homeowner_id)
      ) {
        return [404, { message: 'Property not found.' }];
      }
    }
    const result = await admin
      .from('property_images')
      .select('image_url')
      .eq('property_id', propId)
      .order('sort_order');
    failOn(result.error);
    return [200, result.data.map((item) => item.image_url)];
  }

  const { user, profile } = await requireProfile(request, admin, publicClient);

  if (name === 'google_login.php') {
    const requestedRole = ['homebuyer', 'homeowner'].includes(input.role)
      ? input.role
      : 'homebuyer';
    const current = await ensureProfile(admin, user, {
      full_name: input.name,
      role: requestedRole,
      has_password: false,
    });
    return [200, authPayload(null, current)];
  }

  if (name === 'get_user_profile.php') {
    return [
      200,
      {
        id: profile.id,
        email: profile.email,
        name: profile.full_name,
        phone: profile.phone,
        profile_pic: profile.profile_pic,
        user_type: profile.role,
        has_password: profile.has_password,
        created_at: profile.created_at,
      },
    ];
  }

  if (name === 'update_profile.php') {
    const result = await admin
      .from('profiles')
      .update({
        full_name: String(input.name || '').trim(),
        phone: String(input.phone || '').trim(),
        profile_pic: String(input.profile_pic || '').trim() || null,
      })
      .eq('id', profile.id);
    failOn(result.error);
    return [200, { message: 'Profile updated successfully.' }];
  }

  if (name === 'get_my_properties.php') {
    const result = await admin
      .from('properties')
      .select('*')
      .eq('homeowner_id', profile.id)
      .order('created_at', { ascending: false });
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'send_inquiry.php') {
    const message = String(input.message || '').trim().slice(0, 2500);
    if (!message) return [400, { message: 'A message is required.' }];

    const propertyResult = await admin
      .from('properties')
      .select('id,homeowner_id,name,image_path,status')
      .eq('id', input.property_id)
      .eq('status', 'approved')
      .maybeSingle();
    failOn(propertyResult.error);
    if (!propertyResult.data) {
      return [404, { message: 'Property not found or unavailable for inquiries.' }];
    }
    const property = propertyResult.data;

    const result = await admin.from('inquiries').insert({
      homeowner_id: property.homeowner_id,
      property_id: property.id,
      property_name: property.name,
      property_image: property.image_path,
      buyer_email: profile.email,
      message,
    });
    failOn(result.error);
    return [200, { message: 'Inquiry sent successfully.' }];
  }

  if (name === 'get_inquiries.php') {
    const result = await admin
      .from('inquiries')
      .select('*')
      .eq('homeowner_id', profile.id)
      .order('created_at', { ascending: false });
    failOn(result.error);
    return [200, result.data];
  }

  // Real-Time 2-Way Chat & Viewing Appointment Endpoints
  if (name === 'get_or_create_conversation.php') {
    const propertyId = Number(input.property_id);
    if (!propertyId) {
      return [400, { message: 'property_id is required.' }];
    }
    const propRes = await admin.from('properties').select('*').eq('id', propertyId).maybeSingle();
    failOn(propRes.error);
    if (!propRes.data) {
      return [404, { message: 'Property not found.' }];
    }
    const property = propRes.data;
    const buyerId = profile.id;
    const homeownerId = property.homeowner_id;

    // Check if conversation exists
    let convRes = await admin
      .from('conversations')
      .select('*')
      .eq('property_id', propertyId)
      .eq('buyer_id', buyerId)
      .maybeSingle();
    failOn(convRes.error);

    let conversation = convRes.data;
    if (!conversation) {
      const createRes = await admin
        .from('conversations')
        .insert({
          property_id: propertyId,
          buyer_id: buyerId,
          homeowner_id: homeownerId,
          last_message: 'Conversation started',
          last_message_at: new Date().toISOString(),
        })
        .select('*')
        .single();
      failOn(createRes.error);
      conversation = createRes.data;
    }

    // Fetch other user profile
    const otherUserId = buyerId === profile.id ? homeownerId : buyerId;
    const otherProfileRes = await admin.from('profiles').select('id, full_name, email, role, profile_pic').eq('id', otherUserId).maybeSingle();

    return [200, {
      ...conversation,
      property: propertyJson(property),
      other_user: otherProfileRes.data || { id: otherUserId, full_name: 'Estate Agent', email: '' },
    }];
  }

  if (name === 'get_conversations.php') {
    // Fetch conversations for the current profile
    const convsRes = await admin
      .from('conversations')
      .select('*, properties(*), buyer:profiles!buyer_id(id, full_name, email, role, profile_pic), homeowner:profiles!homeowner_id(id, full_name, email, role, profile_pic)')
      .or(`buyer_id.eq.${profile.id},homeowner_id.eq.${profile.id}`)
      .order('last_message_at', { ascending: false });
    failOn(convsRes.error);

    // Calculate unread count for each conversation
    const conversations = await Promise.all((convsRes.data || []).map(async (c) => {
      const otherUser = c.buyer_id === profile.id ? c.homeowner : c.buyer;
      const unreadRes = await admin
        .from('messages')
        .select('id', { count: 'exact', head: true })
        .eq('conversation_id', c.id)
        .neq('sender_id', profile.id)
        .eq('is_read', false);
      return {
        id: c.id,
        property_id: c.property_id,
        buyer_id: c.buyer_id,
        homeowner_id: c.homeowner_id,
        last_message: c.last_message,
        last_message_at: c.last_message_at,
        created_at: c.created_at,
        property: c.properties ? propertyJson(c.properties) : null,
        other_user: otherUser || { id: 0, full_name: 'Estate Agent', email: '' },
        unread_count: unreadRes.count || 0,
      };
    }));

    return [200, conversations];
  }

  if (name === 'get_messages.php') {
    const conversationId = Number(input.conversation_id || input.id);
    if (!conversationId) {
      return [400, { message: 'conversation_id is required.' }];
    }

    await assertConversationParticipant(admin, profile, conversationId);

    // Mark incoming messages as read
    await admin
      .from('messages')
      .update({ is_read: true })
      .eq('conversation_id', conversationId)
      .neq('sender_id', profile.id);

    const msgsRes = await admin
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true });
    failOn(msgsRes.error);
    return [200, msgsRes.data || []];
  }

  if (name === 'send_message.php') {
    const conversationId = Number(input.conversation_id);
    const messageText = String(input.message_text || input.message || '').trim().slice(0, 5000);
    const messageType = String(input.message_type || 'text').trim();
    const viewingDate = input.viewing_date ? String(input.viewing_date).trim() : null;
    const viewingTime = input.viewing_time ? String(input.viewing_time).trim() : null;
    const viewingMode = input.viewing_mode ? String(input.viewing_mode).trim() : null;

    if (!conversationId || (!messageText && messageType === 'text')) {
      return [400, { message: 'conversation_id and message content are required.' }];
    }

    await assertConversationParticipant(admin, profile, conversationId);

    const newMsg = {
      conversation_id: conversationId,
      sender_id: profile.id,
      message_text: messageText || (messageType === 'viewing_request' ? `Requested viewing on ${viewingDate} (${viewingTime})` : ''),
      message_type: messageType,
      viewing_date: viewingDate,
      viewing_time: viewingTime,
      viewing_mode: viewingMode,
      viewing_status: messageType === 'viewing_request' ? 'pending' : null,
      is_read: false,
    };

    const msgRes = await admin.from('messages').insert(newMsg).select('*').single();
    failOn(msgRes.error);

    // Update conversation last_message
    const previewText = messageType === 'viewing_request' ? `📅 Viewing Request: ${viewingDate}` : messageText;
    await admin
      .from('conversations')
      .update({
        last_message: previewText,
        last_message_at: new Date().toISOString(),
      })
      .eq('id', conversationId);

    return [200, msgRes.data];
  }

  if (name === 'update_viewing_status.php') {
    const messageId = Number(input.message_id);
    const newStatus = String(input.status || input.viewing_status || '').trim(); // 'confirmed', 'rescheduled', 'declined'
    if (!messageId || !['confirmed', 'rescheduled', 'declined'].includes(newStatus)) {
      return [400, { message: 'Valid message_id and status are required.' }];
    }

    const msgLookup = await admin
      .from('messages')
      .select('id, conversation_id, sender_id, message_type')
      .eq('id', messageId)
      .maybeSingle();
    failOn(msgLookup.error);

    if (!msgLookup.data) {
      return [404, { message: 'Message not found.' }];
    }

    await assertConversationParticipant(admin, profile, msgLookup.data.conversation_id);

    const updateRes = await admin
      .from('messages')
      .update({ viewing_status: newStatus })
      .eq('id', messageId)
      .select('*')
      .single();
    failOn(updateRes.error);

    return [200, { message: 'Viewing status updated successfully.', message_data: updateRes.data }];
  }

  if (name === 'create_support_ticket.php') {
    const subject = String(input.subject || '').trim().slice(0, 200);
    const description = String(input.description || '').trim().slice(0, 5000);
    if (!subject || !description) {
      return [400, { message: 'Subject and description are required.' }];
    }

    let attachmentUrls = [];
    try {
      attachmentUrls = JSON.parse(input.attachment_urls || '[]');
    } catch (_) {
      return [400, { message: 'Invalid attachment list.' }];
    }
    if (!Array.isArray(attachmentUrls)) {
      return [400, { message: 'Invalid attachment list.' }];
    }
    attachmentUrls = attachmentUrls.slice(0, 10).map(u => String(u).trim().slice(0, 500));

    const result = await admin.from('support_tickets').insert({
      profile_id: profile.id,
      user_email: profile.email,
      subject,
      description,
      attachment_urls: attachmentUrls,
    });
    failOn(result.error);
    return [200, { message: 'Support ticket created successfully.' }];
  }

  if (name === 'add_property.php') {
    if (!['homeowner', 'admin'].includes(profile.role)) {
      return [403, { message: 'Only homeowners can add properties.' }];
    }
    const nameStr = String(input.name || '').trim().slice(0, 150);
    const locStr = String(input.location || '').trim().slice(0, 200);
    const priceNum = parseFloat(String(input.price || '').replace(/[^0-9.]/g, '')) || 0;
    const descStr = String(input.description || '').trim().slice(0, 5000);
    const imagePathStr = String(input.image_path || '').trim().slice(0, 500);
    const modelPathStr = String(input.model_path || '').trim().slice(0, 500);

    const propertyTypeStr = String(input.property_type || 'Modern Luxury').trim().slice(0, 100);

    if (!nameStr || !locStr || !priceNum || !imagePathStr) {
      return [400, { message: 'Title, location, price, and primary image are required.' }];
    }

    const result = await admin
      .from('properties')
      .insert({
        homeowner_id: profile.id,
        name: nameStr,
        location: locStr,
        property_type: propertyTypeStr,
        price: priceNum,
        description: descStr,
        image_path: imagePathStr,
        model_path: modelPathStr,
        status: profile.role === 'admin' ? 'approved' : 'pending',
      })
      .select('id')
      .single();
    failOn(result.error);

    const images = String(input.gallery_images || '')
      .split(',')
      .map((url) => url.trim().slice(0, 500))
      .filter(Boolean)
      .slice(0, 20)
      .map((image_url, sort_order) => ({
        property_id: result.data.id,
        image_url,
        sort_order,
      }));
    if (images.length) {
      const imageResult = await admin.from('property_images').insert(images);
      failOn(imageResult.error);
    }
    return [200, { message: 'Property added successfully.', id: result.data.id }];
  }

  if (name === 'edit_property.php') {
    await assertPropertyOwner(admin, profile, input.property_id);
    const nameStr = String(input.name || '').trim().slice(0, 150);
    const locStr = String(input.location || '').trim().slice(0, 200);
    const priceNum = parseFloat(String(input.price || '').replace(/[^0-9.]/g, '')) || 0;
    const descStr = String(input.description || '').trim().slice(0, 5000);
    const imagePathStr = String(input.image_path || '').trim().slice(0, 500);
    const modelPathStr = String(input.model_path || '').trim().slice(0, 500);

    const updates = {
      name: nameStr,
      location: locStr,
      price: priceNum,
      description: descStr,
      image_path: imagePathStr,
      model_path: modelPathStr,
    };
    if (input.property_type) {
      updates.property_type = String(input.property_type).trim().slice(0, 100);
    }
    if (profile.role !== 'admin') updates.status = 'pending';
    const result = await admin
      .from('properties')
      .update(updates)
      .eq('id', input.property_id);
    failOn(result.error);
    return [200, { message: 'Property updated successfully.' }];
  }

  if (name === 'delete_property.php') {
    await assertPropertyOwner(admin, profile, input.property_id);
    const result = await admin.from('properties').delete().eq('id', input.property_id);
    failOn(result.error);
    return [200, { message: 'Property deleted successfully.' }];
  }

  if (name === 'get_pending_properties.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const result = await admin
      .from('properties')
      .select('*')
      .eq('status', 'pending')
      .order('created_at');
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'get_all_properties_admin.php' || name === 'get_all_admin_properties.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const result = await admin
      .from('properties')
      .select('*, profiles:homeowner_id(full_name, email)')
      .order('created_at', { ascending: false });
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'get_admin_users.php' || name === 'get_all_users.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const result = await admin
      .from('profiles')
      .select('id, full_name, email, role, phone, profile_pic, created_at')
      .order('created_at', { ascending: false });
    failOn(result.error);
    const mappedUsers = (result.data || []).map((u) => ({
      id: u.id,
      full_name: u.full_name,
      email: u.email,
      role: u.role,
      phone_number: u.phone || '',
      profile_pic: u.profile_pic,
      created_at: u.created_at,
    }));
    return [200, mappedUsers];
  }

  if (name === 'create_property_type.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const nameStr = String(input.name || '').trim().slice(0, 100);
    const iconStr = String(input.icon || 'home_work_rounded').trim().slice(0, 50);
    if (!nameStr) {
      return [400, { message: 'Property type name is required.' }];
    }
    const result = await admin
      .from('property_types')
      .insert({ name: nameStr, icon: iconStr })
      .select()
      .single();
    failOn(result.error);
    return [200, { message: 'Property type created.', data: result.data }];
  }

  if (name === 'update_property_type.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const id = input.id;
    const nameStr = String(input.name || '').trim().slice(0, 100);
    const iconStr = String(input.icon || '').trim().slice(0, 50);
    if (!id || !nameStr) {
      return [400, { message: 'ID and name are required.' }];
    }
    const current = await admin.from('property_types').select('name').eq('id', id).single();
    failOn(current.error);
    const oldName = current.data?.name;

    const updates = { name: nameStr };
    if (iconStr) updates.icon = iconStr;
    const result = await admin.from('property_types').update(updates).eq('id', id).select().single();
    failOn(result.error);

    if (oldName && oldName !== nameStr) {
      await admin.from('properties').update({ property_type: nameStr }).eq('property_type', oldName);
    }
    return [200, { message: 'Property type updated.', data: result.data }];
  }

  if (name === 'delete_property_type.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const id = input.id;
    if (!id) return [400, { message: 'Property type ID is required.' }];

    const current = await admin.from('property_types').select('name').eq('id', id).single();
    if (current.data) {
      const typeName = current.data.name;
      // Reassign all listings of this type to default 'Modern Luxury'
      await admin.from('properties').update({ property_type: 'Modern Luxury' }).eq('property_type', typeName);
    }

    const result = await admin.from('property_types').delete().eq('id', id);
    failOn(result.error);
    return [200, { message: 'Property type deleted and associated properties reassigned.' }];
  }

  if (name === 'update_user_role.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const allowedRoles = new Set(['homebuyer', 'homeowner', 'admin']);
    if (!allowedRoles.has(input.role)) {
      return [400, { message: 'Invalid role specified.' }];
    }
    let query = admin.from('profiles').update({ role: input.role });
    if (input.user_id) {
      query = query.eq('id', input.user_id);
    } else if (input.email) {
      query = query.eq('email', input.email);
    } else {
      return [400, { message: 'user_id or email is required.' }];
    }
    const result = await query;
    failOn(result.error);
    return [200, { message: 'User role updated successfully.' }];
  }

  if (name === 'get_admin_stats.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const [usersRes, propsRes, pendingRes, inquiriesRes, favoritesRes] = await Promise.all([
      admin.from('profiles').select('id', { count: 'exact', head: true }),
      admin.from('properties').select('id', { count: 'exact', head: true }),
      admin.from('properties').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      admin.from('inquiries').select('id', { count: 'exact', head: true }),
      admin.from('favorites').select('id', { count: 'exact', head: true }),
    ]);
    return [200, {
      total_users: usersRes.count || 0,
      total_properties: propsRes.count || 0,
      pending_moderation: pendingRes.count || 0,
      total_inquiries: inquiriesRes.count || 0,
      total_favorites: favoritesRes.count || 0,
    }];
  }

  if (name === 'toggle_property_featured.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const isFeatured = input.is_featured === true || input.is_featured === '1' || input.is_featured === 'true';
    const result = await admin
      .from('properties')
      .update({ is_featured: isFeatured })
      .eq('id', input.property_id);
    failOn(result.error);
    return [200, { message: `Property marked as ${isFeatured ? 'featured' : 'standard'}.` }];
  }

  if (name === 'update_property_status.php') {
    if (profile.role !== 'admin') {
      return [403, { message: 'Admin access required.' }];
    }
    const allowed = new Set(['pending', 'approved', 'rejected', 'sold', 'draft']);
    if (!allowed.has(input.status)) {
      return [400, { message: 'Invalid property status.' }];
    }
    const result = await admin
      .from('properties')
      .update({ status: input.status })
      .eq('id', input.property_id);
    failOn(result.error);
    return [200, { message: 'Property status updated.' }];
  }

  if (name === 'check_favorite.php') {
    const result = await admin
      .from('favorites')
      .select('id')
      .eq('profile_id', profile.id)
      .eq('property_id', input.property_id)
      .maybeSingle();
    failOn(result.error);
    return [200, { isFavorited: Boolean(result.data) }];
  }

  if (name === 'add_favorite.php') {
    const result = await admin.from('favorites').upsert(
      { profile_id: profile.id, property_id: input.property_id },
      { onConflict: 'profile_id,property_id', ignoreDuplicates: true },
    );
    failOn(result.error);
    return [200, { message: 'Favorite added.' }];
  }

  if (name === 'remove_favorite.php') {
    const result = await admin
      .from('favorites')
      .delete()
      .eq('profile_id', profile.id)
      .eq('property_id', input.property_id);
    failOn(result.error);
    return [200, { message: 'Favorite removed.' }];
  }

  if (name === 'get_favorites.php') {
    const result = await admin
      .from('favorites')
      .select('properties(*)')
      .eq('profile_id', profile.id)
      .order('created_at', { ascending: false });
    failOn(result.error);
    return [
      200,
      result.data
        .map((item) => item.properties)
        .filter(Boolean)
        .map(propertyJson),
    ];
  }

  if (name === 'change_password.php') {
    const currentPassword = String(input.current_password || '');
    const newPassword = String(input.new_password || '');

    const passwordError = validatePasswordStrength(newPassword);
    if (passwordError) {
      return [400, { message: passwordError }];
    }

    const verified = await publicClient.auth.signInWithPassword({
      email: user.email,
      password: currentPassword,
    });
    if (verified.error) {
      return [401, { message: 'Current password is incorrect.' }];
    }
    const userSession = verified.data?.session;
    if (userSession?.access_token) {
      const publishableKey =
        process.env.SUPABASE_PUBLISHABLE_KEY ||
        process.env.SUPABASE_ANON_KEY ||
        requiredEnv('SUPABASE_PUBLISHABLE_KEY');
      const authClient = createClient(requiredEnv('SUPABASE_URL'), publishableKey, {
        auth: { persistSession: false, autoRefreshToken: false },
        global: { headers: { Authorization: `Bearer ${userSession.access_token}` } },
      });
      const updateRes = await authClient.auth.updateUser({
        password: newPassword,
        data: { ...user.user_metadata, has_password: true },
      });
      failOn(updateRes.error);
    } else if (admin.auth?.admin?.updateUserById) {
      const result = await admin.auth.admin.updateUserById(user.id, {
        password: newPassword,
        user_metadata: { ...user.user_metadata, has_password: true },
      });
      failOn(result.error);
    }
    const profileResult = await admin
      .from('profiles')
      .update({ has_password: true })
      .eq('id', profile.id);
    failOn(profileResult.error);
    return [200, { message: 'Password changed successfully.' }];
  }

  if (name === 'deactivate_account.php') {
    if (profile.has_password) {
      const verified = await publicClient.auth.signInWithPassword({
        email: user.email,
        password: String(input.password || ''),
      });
      if (verified.error) return [401, { message: 'Password is incorrect.' }];
    }
    const result = await admin
      .from('profiles')
      .update({ is_active: false })
      .eq('id', profile.id);
    failOn(result.error);
    return [200, { message: 'Account deactivated successfully.' }];
  }

  if (name === 'delete_account.php') {
    // GDPR Art. 17 / CCPA § 1798.105: Permanent Right to Erasure
    if (profile.has_password) {
      const verified = await publicClient.auth.signInWithPassword({
        email: user.email,
        password: String(input.password || ''),
      });
      if (verified.error) return [401, { message: 'Password is incorrect.' }];
    }

    // 1. Delete user files from storage buckets
    try {
      if (profile.profile_pic) {
        const urlSegments = profile.profile_pic.split('/avatars/');
        if (urlSegments.length > 1) {
          await admin.storage.from('avatars').remove([urlSegments[1]]);
        }
      }
      if (user && user.id) {
        const { data: propFiles } = await admin.storage.from('property-assets').list(user.id);
        if (propFiles && propFiles.length > 0) {
          await admin.storage.from('property-assets').remove(propFiles.map((f) => `${user.id}/${f.name}`));
        }
        const { data: ticketFiles } = await admin.storage.from('support-attachments').list(user.id);
        if (ticketFiles && ticketFiles.length > 0) {
          await admin.storage.from('support-attachments').remove(ticketFiles.map((f) => `${user.id}/${f.name}`));
        }
        const { data: avatarFiles } = await admin.storage.from('avatars').list(user.id);
        if (avatarFiles && avatarFiles.length > 0) {
          await admin.storage.from('avatars').remove(avatarFiles.map((f) => `${user.id}/${f.name}`));
        }
      }
    } catch (_) {}

    // 2. Anonymize user records in inquiries
    await admin
      .from('inquiries')
      .update({ buyer_email: `anonymized_${profile.id}@erased.vizare.com` })
      .eq('buyer_email', profile.email);

    // 3. Purge user profile & notification preferences
    await admin.from('favorites').delete().eq('profile_id', profile.id);
    await admin.from('notification_preferences').delete().eq('profile_id', profile.id);
    await admin.from('support_tickets').delete().eq('profile_id', profile.id);
    await admin.from('profiles').delete().eq('id', profile.id);

    // 4. Delete auth user if admin API is available
    if (admin.auth?.admin?.deleteUser && user && user.id) {
      try {
        await admin.auth.admin.deleteUser(user.id);
      } catch (_) {}
    }

    return [200, { message: 'Account and personal data permanently erased.' }];
  }

  if (name === 'export_my_data.php') {
    // GDPR Art. 20 / CCPA § 1798.130: Right of Access & Data Portability
    const [propertiesRes, favoritesRes, inquiriesRes, ticketsRes, prefsRes] = await Promise.all([
      admin.from('properties').select('*').eq('homeowner_id', profile.id),
      admin.from('favorites').select('properties(*)').eq('profile_id', profile.id),
      admin.from('inquiries').select('*').or(`homeowner_id.eq.${profile.id},buyer_email.eq.${profile.email}`),
      admin.from('support_tickets').select('*').eq('profile_id', profile.id),
      admin.from('notification_preferences').select('*').eq('profile_id', profile.id).maybeSingle(),
    ]);

    return [
      200,
      {
        profile: {
          id: profile.id,
          email: profile.email,
          full_name: profile.full_name,
          phone: profile.phone,
          role: profile.role,
          created_at: profile.created_at,
          consent_terms_at: profile.consent_terms_at,
          consent_privacy_at: profile.consent_privacy_at,
          consent_version: profile.consent_version,
        },
        properties: propertiesRes.data || [],
        favorites: (favoritesRes.data || []).map(f => f.properties).filter(Boolean),
        inquiries: inquiriesRes.data || [],
        support_tickets: ticketsRes.data || [],
        notification_preferences: prefsRes.data || null,
        exported_at: new Date().toISOString(),
      },
    ];
  }

  return [404, { message: `Unknown API route: ${name}` }];
}

const MUTATING_ROUTES = new Set([
  'create_account.php',
  'login.php',
  'google_login.php',
  'update_profile.php',
  'send_inquiry.php',
  'create_support_ticket.php',
  'add_property.php',
  'edit_property.php',
  'delete_property.php',
  'update_property_status.php',
  'add_favorite.php',
  'remove_favorite.php',
  'change_password.php',
  'deactivate_account.php',
  'delete_account.php',
  'get_or_create_conversation.php',
  'send_message.php',
  'update_viewing_status.php',
  'resend_verification.php',
  'forgot_password.php',
]);

module.exports = async function handler(request, response) {
  Object.entries(corsHeaders(request)).forEach(([key, value]) =>
    response.setHeader(key, value),
  );
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['GET', 'POST'].includes(request.method)) {
    return response.status(405).json({ message: 'Method not allowed.' });
  }

  const name = routeName(request);
  if (MUTATING_ROUTES.has(name) && request.method !== 'POST') {
    return response.status(405).json({ message: `HTTP method ${request.method} not allowed for ${name}. Must use POST.` });
  }
  try {
    if (name === 'client_config.php') {
      return response.status(200).json({
        supabase_url: process.env.SUPABASE_URL || '',
        supabase_publishable_key:
          process.env.SUPABASE_PUBLISHABLE_KEY || '',
        google_maps_api_key: process.env.GOOGLE_MAPS_API_KEY || '',
        google_oauth_client_id:
          process.env.GOOGLE_OAUTH_CLIENT_ID ||
          process.env.GOOGLE_CLIENT_ID ||
          '',
      });
    }
    const { admin, publicClient } = createClients();
    const [status, payload] = await dispatch(
      name,
      request,
      admin,
      publicClient,
    );
    return response.status(status).json(payload);
  } catch (error) {
    console.error(`API route ${name} failed:`, error);
    if (error.code === 'SERVER_CONFIGURATION_ERROR') {
      return response.status(503).json({
        message:
          'The API is not configured. Check the Supabase environment variables in Vercel.',
      });
    }
    const status =
      typeof error.status === 'number' &&
      error.status >= 400 &&
      error.status < 600
        ? error.status
        : 500;
    return response.status(status).json({
      message: error.message || 'The server could not complete the request.',
    });
  }
};
