const { createClient } = require('@supabase/supabase-js');

function corsHeaders(request) {
  return {
    'Access-Control-Allow-Origin': request.headers.origin || '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers':
      request.headers['access-control-request-headers'] ||
      'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function createClients() {
  const url = requiredEnv('SUPABASE_URL');
  const options = { auth: { autoRefreshToken: false, persistSession: false } };
  return {
    admin: createClient(
      url,
      requiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
      options,
    ),
    publicClient: createClient(
      url,
      process.env.SUPABASE_PUBLISHABLE_KEY || requiredEnv('SUPABASE_ANON_KEY'),
      options,
    ),
  };
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
    request.on('data', (chunk) => (data += chunk));
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
  return { ...property, is_featured: property.is_featured ? 1 : 0 };
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

async function profileForUser(admin, user) {
  let result = await admin
    .from('profiles')
    .select('*')
    .eq('auth_user_id', user.id)
    .maybeSingle();
  failOn(result.error);

  // Link records imported from the old MySQL database on first login.
  if (!result.data && user.email) {
    result = await admin
      .from('profiles')
      .update({ auth_user_id: user.id })
      .eq('email', user.email)
      .is('auth_user_id', null)
      .select('*')
      .maybeSingle();
    failOn(result.error);
  }
  return result.data;
}

async function requireProfile(request, admin, publicClient) {
  const user = await getAuthUser(request, publicClient);
  if (!user) throw Object.assign(new Error('Authentication required.'), { status: 401 });
  const profile = await profileForUser(admin, user);
  if (!profile || !profile.is_active) {
    throw Object.assign(new Error('Account is unavailable.'), { status: 403 });
  }
  return { user, profile };
}

async function ensureProfile(admin, user, values = {}) {
  const existing = await profileForUser(admin, user);
  if (existing) return existing;

  const metadata = user.user_metadata || {};
  const result = await admin
    .from('profiles')
    .insert({
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
    })
    .select('*')
    .single();
  failOn(result.error);
  return result.data;
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

async function dispatch(name, request, admin, publicClient) {
  const input = request.method === 'GET' ? query(request) : await readBody(request);

  if (name === 'create_account.php') {
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
    const result = await publicClient.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName, role, has_password: true } },
    });
    if (result.error) {
      return [result.error.status || 400, { message: result.error.message }];
    }
    if (!result.data.user || result.data.user.identities?.length === 0) {
      return [409, { message: 'An account with this email already exists.' }];
    }
    const profile = await ensureProfile(admin, result.data.user, {
      full_name: fullName,
      role,
      has_password: true,
    });
    return [
      200,
      authPayload(result.data.session, profile, {
        message: result.data.session
          ? 'Account created successfully.'
          : 'Account created. Check your email to confirm your account.',
        requires_email_confirmation: !result.data.session,
      }),
    ];
  }

  if (name === 'login.php') {
    const result = await publicClient.auth.signInWithPassword({
      email: String(input.email || '').trim().toLowerCase(),
      password: String(input.password || ''),
    });
    if (result.error) return [401, { message: 'Invalid email or password.' }];
    const profile = await ensureProfile(admin, result.data.user);
    if (!profile.is_active) {
      return [403, { message: 'This account has been deactivated.' }];
    }
    return [200, authPayload(result.data.session, profile)];
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

  if (name === 'search_properties.php') {
    const term = String(input.term || '').trim().replace(/[%_,()]/g, '');
    let builder = admin
      .from('properties')
      .select('*')
      .eq('status', 'approved')
      .order('created_at', { ascending: false });
    if (term) {
      builder = builder.or(
        `name.ilike.%${term}%,location.ilike.%${term}%,description.ilike.%${term}%`,
      );
    }
    const result = await builder;
    failOn(result.error);
    return [200, result.data.map(propertyJson)];
  }

  if (name === 'get_property_images.php') {
    const result = await admin
      .from('property_images')
      .select('image_url')
      .eq('property_id', input.property_id)
      .order('sort_order');
    failOn(result.error);
    return [200, result.data.map((item) => item.image_url)];
  }

  const { user, profile } = await requireProfile(request, admin, publicClient);

  if (name === 'google_login.php') {
    const current = await ensureProfile(admin, user, {
      full_name: input.name,
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

  if (name === 'add_property.php') {
    if (!['homeowner', 'admin'].includes(profile.role)) {
      return [403, { message: 'Only homeowners can add properties.' }];
    }
    const result = await admin
      .from('properties')
      .insert({
        homeowner_id: profile.id,
        name: input.name,
        location: input.location,
        price: input.price,
        description: input.description,
        image_path: input.image_path,
        model_path: input.model_path || '',
        status: profile.role === 'admin' ? 'approved' : 'pending',
      })
      .select('id')
      .single();
    failOn(result.error);

    const images = String(input.gallery_images || '')
      .split(',')
      .map((url) => url.trim())
      .filter(Boolean)
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
    const updates = {
      name: input.name,
      location: input.location,
      price: input.price,
      description: input.description,
      image_path: input.image_path,
    };
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
    const verified = await publicClient.auth.signInWithPassword({
      email: user.email,
      password: String(input.current_password || ''),
    });
    if (verified.error) {
      return [401, { message: 'Current password is incorrect.' }];
    }
    const result = await admin.auth.admin.updateUserById(user.id, {
      password: String(input.new_password || ''),
      user_metadata: { ...user.user_metadata, has_password: true },
    });
    failOn(result.error);
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

  return [404, { message: `Unknown API route: ${name}` }];
}

module.exports = async function handler(request, response) {
  Object.entries(corsHeaders(request)).forEach(([key, value]) =>
    response.setHeader(key, value),
  );
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['GET', 'POST'].includes(request.method)) {
    return response.status(405).json({ message: 'Method not allowed.' });
  }

  const name = routeName(request);
  try {
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
    return response.status(error.status || 500).json({
      message: error.status
        ? error.message
        : 'The server could not complete the request.',
    });
  }
};
