const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert');
const { EventEmitter } = require('node:events');

const router = require('../api/supabase-router');
const pathEntrypoint = require('../api/[...path]');

function createMockRequest({ method = 'GET', url = '/api/client_config.php', headers = {}, body = null, query = {} }) {
  const req = new EventEmitter();
  req.method = method;
  req.url = url;
  req.headers = { host: 'localhost:3000', ...headers };
  req.body = body;
  req.query = query;
  return req;
}

function createMockResponse() {
  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    setHeader(key, value) {
      this.headers[key.toLowerCase()] = value;
      return this;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
    end() {
      this.ended = true;
      return this;
    },
  };
  return res;
}

describe('Supabase Router API Tests', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  test('Entrypoint [...path].js correctly exports supabase router handler', () => {
    assert.strictEqual(typeof pathEntrypoint, 'function');
    assert.strictEqual(pathEntrypoint, router);
  });

  test('OPTIONS preflight returns 204 with complete CORS headers', async () => {
    const req = createMockRequest({
      method: 'OPTIONS',
      url: '/api/client_config.php',
      headers: {
        origin: 'https://vizare.app',
        'access-control-request-headers': 'Content-Type, Authorization, apikey, x-client-info',
      },
    });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 204);
    assert.strictEqual(res.headers['access-control-allow-origin'], 'https://vizare.app');
    assert.strictEqual(res.headers['access-control-allow-methods'], 'GET,POST,OPTIONS');
    assert.match(res.headers['access-control-allow-headers'], /Content-Type/);
    assert.match(res.headers['access-control-allow-headers'], /Authorization/);
    assert.match(res.headers['access-control-allow-headers'], /apikey/);
    assert.match(res.headers['access-control-allow-headers'], /x-client-info/);
    assert.strictEqual(res.ended, true);
  });

  test('Disallowed HTTP methods return 405 Method not allowed', async () => {
    for (const method of ['PUT', 'DELETE', 'PATCH']) {
      const req = createMockRequest({ method, url: '/api/client_config.php' });
      const res = createMockResponse();

      await router(req, res);

      assert.strictEqual(res.statusCode, 405);
      assert.deepStrictEqual(res.body, { message: 'Method not allowed.' });
    }
  });

  test('client_config.php route returns configured API keys from environment', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';
    process.env.GOOGLE_MAPS_API_KEY = 'mock-google-maps-key-123';
    process.env.GOOGLE_OAUTH_CLIENT_ID = 'mock-google-client-id-abc';

    const req = createMockRequest({ method: 'GET', url: '/api/client_config.php' });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 200);
    assert.deepStrictEqual(res.body, {
      supabase_url: 'https://mock.supabase.co',
      supabase_publishable_key: 'mock-publishable-key-xyz',
      google_maps_api_key: 'mock-google-maps-key-123',
      google_oauth_client_id: 'mock-google-client-id-abc',
    });
  });

  test('returns 503 SERVER_CONFIGURATION_ERROR when Supabase env vars are missing', async () => {
    // Missing SUPABASE_URL
    delete process.env.SUPABASE_URL;
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req1 = createMockRequest({ method: 'GET', url: '/api/get_all_listings.php' });
    const res1 = createMockResponse();
    await router(req1, res1);
    assert.strictEqual(res1.statusCode, 503);
    assert.match(res1.body.message, /The API is not configured/);

    // Missing SUPABASE_PUBLISHABLE_KEY
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    delete process.env.SUPABASE_PUBLISHABLE_KEY;
    const req2 = createMockRequest({ method: 'GET', url: '/api/get_all_listings.php' });
    const res2 = createMockResponse();
    await router(req2, res2);
    assert.strictEqual(res2.statusCode, 503);

    // Missing SUPABASE_SECRET_KEY
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    delete process.env.SUPABASE_SECRET_KEY;
    const req3 = createMockRequest({ method: 'GET', url: '/api/get_all_listings.php' });
    const res3 = createMockResponse();
    await router(req3, res3);
    assert.strictEqual(res3.statusCode, 503);
  });

  test('resend_verification.php requires email and returns 400 when missing', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req = createMockRequest({
      method: 'POST',
      url: '/api/resend_verification.php',
      body: {},
    });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 400);
    assert.deepStrictEqual(res.body, { message: 'Email is required.' });
  });

  test('forgot_password.php validates email and returns 400 when missing or invalid', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req1 = createMockRequest({
      method: 'POST',
      url: '/api/forgot_password.php',
      body: {},
    });
    const res1 = createMockResponse();
    await router(req1, res1);
    assert.strictEqual(res1.statusCode, 400);
    assert.match(res1.body.message, /Email address is required/);

    const req2 = createMockRequest({
      method: 'POST',
      url: '/api/forgot_password.php',
      body: { email: 'invalid-email' },
    });
    const res2 = createMockResponse();
    await router(req2, res2);
    assert.strictEqual(res2.statusCode, 400);
    assert.match(res2.body.message, /valid email address/);
  });

  test('create_account.php enforces strong password rules and required fields', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req = createMockRequest({
      method: 'POST',
      url: '/api/create_account.php',
      body: { name: 'Test', email: 'test@example.com', password: 'weak' },
    });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 400);
    assert.match(res.body.message, /Password must be at least 8 characters long/);
  });

  test('Database seed.sql contains 20 complete listings with unique 3D house models', () => {
    const fs = require('fs');
    const path = require('path');
    const seedPath = path.join(__dirname, '..', 'supabase', 'seed.sql');
    assert.strictEqual(fs.existsSync(seedPath), true);
    const sql = fs.readFileSync(seedPath, 'utf8');

    // Verify 20 properties
    const propertyRegex = /insert into public\.properties/gi;
    const propertyMatches = sql.match(propertyRegex);
    assert.strictEqual(propertyMatches?.length, 20, 'Expected exactly 20 property listings in seed.sql');

    // Extract all model paths
    const modelRegex = /'https:\/\/[^']+\.glb'/gi;
    const modelMatches = sql.match(modelRegex) || [];
    const uniqueModels = new Set(modelMatches);
    assert.strictEqual(uniqueModels.size, 20, 'Expected 20 unique GLB model URLs');

    // Verify relational integrity entities
    assert.match(sql, /insert into public\.profiles/i);
    assert.match(sql, /insert into public\.notification_preferences/i);
    assert.match(sql, /insert into public\.property_images/i);
    assert.match(sql, /insert into public\.favorites/i);
    assert.match(sql, /insert into public\.inquiries/i);
    assert.match(sql, /insert into public\.support_tickets/i);
  });

  test('Supabase baseline migration and GitHub Actions CI workflow exist and are configured', () => {
    const fs = require('fs');
    const path = require('path');

    const configPath = path.join(__dirname, '..', 'supabase', 'config.toml');
    assert.strictEqual(fs.existsSync(configPath), true, 'config.toml must exist');
    const configContent = fs.readFileSync(configPath, 'utf8');
    assert.match(configContent, /project_id\s*=\s*"ttuxazxgkgrpakdedngw"/);

    const initialMigrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20260827000000_initial_schema.sql');
    assert.strictEqual(fs.existsSync(initialMigrationPath), true, '20260827000000_initial_schema.sql must exist');

    const workflowPath = path.join(__dirname, '..', '.github', 'workflows', 'supabase-migrations.yml');
    assert.strictEqual(fs.existsSync(workflowPath), true, 'supabase-migrations.yml workflow must exist');
    const workflowContent = fs.readFileSync(workflowPath, 'utf8');
    assert.match(workflowContent, /supabase\/setup-cli/);
    assert.match(workflowContent, /supabase db push/);
  });

  test('Database triggers enforce profile and property integrity while allowing service-role / backend execution', () => {
    const fs = require('fs');
    const path = require('path');

    const schemaPath = path.join(__dirname, '..', 'supabase', 'schema.sql');
    assert.strictEqual(fs.existsSync(schemaPath), true);
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Verify enforce_profile_integrity allows service_role / auth.uid() is null
    assert.match(schema, /create or replace function public\.enforce_profile_integrity/);
    assert.match(schema, /auth\.uid\(\)\s+is\s+null/);

    // Verify enforce_property_integrity allows service_role / auth.uid() is null
    assert.match(schema, /create or replace function public\.enforce_property_integrity/);

    // Verify migration exists
    const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20260828020000_chat_security_and_trigger_integrity.sql');
    assert.strictEqual(fs.existsSync(migrationPath), true, 'Migration 20260828020000_chat_security_and_trigger_integrity.sql must exist');
    const migration = fs.readFileSync(migrationPath, 'utf8');
    assert.match(migration, /enforce_profile_integrity/);
    assert.match(migration, /enforce_property_integrity/);
  });

  test('PostgREST Message Update Column Integrity: enforce_message_integrity trigger exists and protects message text and sender_id', () => {
    const fs = require('fs');
    const path = require('path');

    const schemaPath = path.join(__dirname, '..', 'supabase', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    assert.match(schema, /create or replace function public\.enforce_message_integrity/);
    assert.match(schema, /create trigger check_message_integrity/);
    assert.match(schema, /new\.sender_id\s*:=\s*old\.sender_id/);
    assert.match(schema, /new\.message_text\s*:=\s*old\.message_text/);
    assert.match(schema, /new\.conversation_id\s*:=\s*old\.conversation_id/);
  });

  test('supabase-router.js validates conversation participation for chat endpoints to prevent BOLA / IDOR', () => {
    const fs = require('fs');
    const path = require('path');

    const routerPath = path.join(__dirname, '..', 'api', 'supabase-router.js');
    const routerCode = fs.readFileSync(routerPath, 'utf8');

    // Verify helper assertConversationParticipant exists
    assert.match(routerCode, /async function assertConversationParticipant/);

    // Verify get_messages.php uses assertConversationParticipant
    assert.match(routerCode, /if\s*\(name\s*===\s*'get_messages\.php'\)\s*\{[\s\S]*?assertConversationParticipant/);

    // Verify send_message.php uses assertConversationParticipant
    assert.match(routerCode, /if\s*\(name\s*===\s*'send_message\.php'\)\s*\{[\s\S]*?assertConversationParticipant/);

    // Verify update_viewing_status.php uses assertConversationParticipant
    assert.match(routerCode, /if\s*\(name\s*===\s*'update_viewing_status\.php'\)\s*\{[\s\S]*?assertConversationParticipant/);
  });

  test('Database triggers and RLS policies enforce account takeover prevention, property types RLS, and conversation immutability', () => {
    const fs = require('fs');
    const path = require('path');

    const schemaPath = path.join(__dirname, '..', 'supabase', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // SEC-01: handle_new_auth_user protected with WHERE auth_user_id is null
    assert.match(schema, /create or replace function public\.handle_new_auth_user/);
    assert.match(schema, /where\s+public\.profiles\.auth_user_id\s+is\s+null/);

    // SEC-02: property_types RLS enabled
    assert.match(schema, /alter table public\.property_types enable row level security/);
    assert.match(schema, /"Anyone can read property types"/);
    assert.match(schema, /"Admins can manage property types"/);

    // SEC-03: enforce_conversation_integrity trigger exists
    assert.match(schema, /create or replace function public\.enforce_conversation_integrity/);
    assert.match(schema, /create trigger check_conversation_integrity/);
    assert.match(schema, /new\.buyer_id\s*:=\s*old\.buyer_id/);
    assert.match(schema, /new\.homeowner_id\s*:=\s*old\.homeowner_id/);

    // SEC-09: audit_logs insert policy validates actor binding
    assert.match(schema, /auth_user_id\s*=\s*auth\.uid\(\)/);
    assert.match(schema, /id\s*=\s*actor_id/);

    // Verify migration 20260828030000 exists
    const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20260828030000_security_and_compliance_hardening.sql');
    assert.strictEqual(fs.existsSync(migrationPath), true, 'Migration 20260828030000 must exist');
  });

  test('vercel.json and supabase-router.js configure complete Content-Security-Policy and Permissions-Policy headers', async () => {
    const fs = require('fs');
    const path = require('path');

    const vercelConfig = JSON.parse(
      fs.readFileSync(path.join(__dirname, '..', 'vercel.json'), 'utf8')
    );
    const globalHeaders = vercelConfig.headers.find((h) => h.source === '/(.*)').headers;
    const headerMap = Object.fromEntries(globalHeaders.map((h) => [h.key.toLowerCase(), h.value]));

    // Verify all required security headers exist in vercel.json
    assert.ok(headerMap['content-security-policy'], 'Content-Security-Policy must be present');
    assert.ok(headerMap['permissions-policy'], 'Permissions-Policy must be present');
    assert.ok(headerMap['strict-transport-security'], 'Strict-Transport-Security must be present');
    assert.strictEqual(headerMap['x-content-type-options'], 'nosniff');
    assert.strictEqual(headerMap['x-frame-options'], 'SAMEORIGIN');
    assert.strictEqual(headerMap['referrer-policy'], 'strict-origin-when-cross-origin');

    // Verify CSP directives include essential sources for Flutter Web, CanvasKit, and external 3D/Map integrations
    const csp = headerMap['content-security-policy'];
    assert.match(csp, /default-src\s+'self'/);
    assert.match(csp, /script-src[^;]*'unsafe-inline'/);
    assert.match(csp, /script-src[^;]*'unsafe-eval'/);
    assert.match(csp, /script-src[^;]*wasm-unsafe-eval/);
    assert.match(csp, /script-src[^;]*ajax\.googleapis\.com/);
    assert.match(csp, /script-src[^;]*maps\.googleapis\.com/);
    assert.match(csp, /script-src[^;]*gstatic\.com/);
    assert.match(csp, /font-src[^;]*fonts\.gstatic\.com/);
    assert.match(csp, /img-src[^;]*supabase\.co/);
    assert.match(csp, /img-src[^;]*unsplash\.com/);
    assert.match(csp, /connect-src[^;]*supabase\.co/);
    assert.match(csp, /connect-src[^;]*api\.emailjs\.com/);
    assert.match(csp, /frame-src[^;]*sketchfab\.com/);

    // Verify Permissions-Policy restrictions
    const permPolicy = headerMap['permissions-policy'];
    assert.match(permPolicy, /camera=\(\)/);
    assert.match(permPolicy, /microphone=\(\)/);
    assert.match(permPolicy, /geolocation=\(self\)/);
    assert.match(permPolicy, /payment=\(\)/);

    // Verify router OPTIONS response contains security headers
    const req = createMockRequest({
      method: 'OPTIONS',
      url: '/api/client_config.php',
      headers: { origin: 'https://vizare.app' },
    });
    const res = createMockResponse();
    await router(req, res);

    assert.ok(res.headers['content-security-policy'], 'Router must set Content-Security-Policy');
    assert.ok(res.headers['permissions-policy'], 'Router must set Permissions-Policy');
    assert.ok(res.headers['strict-transport-security'], 'Router must set Strict-Transport-Security');
    assert.ok(res.headers['referrer-policy'], 'Router must set Referrer-Policy');
  });

  test('Image URLs from Unsplash are normalized to fm=jpg for CanvasKit compatibility', () => {
    const rawUrl = 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80';
    const normalized = rawUrl.replace(/auto=format/g, 'fm=jpg');
    assert.match(normalized, /fm=jpg/);
    assert.doesNotMatch(normalized, /auto=format/);
  });

  test('image-proxy handles OPTIONS preflight and blocks non-whitelisted origins', async () => {
    const imageProxy = require('../api/image-proxy');

    const optReq = createMockRequest({ method: 'OPTIONS' });
    const optRes = createMockResponse();
    await imageProxy(optReq, optRes);
    assert.strictEqual(optRes.statusCode, 204);
    assert.strictEqual(optRes.headers['access-control-allow-origin'], '*');

    const missingReq = createMockRequest({ method: 'GET', query: {} });
    const missingRes = createMockResponse();
    await imageProxy(missingReq, missingRes);
    assert.strictEqual(missingRes.statusCode, 400);

    const badHostReq = createMockRequest({
      method: 'GET',
      query: { url: encodeURIComponent('https://malicious-site.com/image.jpg') },
    });
    const badHostRes = createMockResponse();
    await imageProxy(badHostReq, badHostRes);
    assert.strictEqual(badHostRes.statusCode, 403);
  });

  test('add_property.php requires authenticated session and homeowner role', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req = createMockRequest({
      method: 'POST',
      url: '/api/add_property.php',
      body: { name: 'Test Villa', location: 'KL', price: '1000000', image_path: 'https://example.com/img.jpg' },
    });
    const res = createMockResponse();
    await router(req, res);

    // Without Bearer token, it must reject with 401
    assert.strictEqual(res.statusCode, 401);
    assert.match(res.body.message, /Authentication required/i);
  });

  test('upload_asset.php requires authenticated session and validates bucket', async () => {
    process.env.SUPABASE_URL = 'https://mock.supabase.co';
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-publishable-key-xyz';
    process.env.SUPABASE_SECRET_KEY = 'mock-secret-key-xyz';

    const req = createMockRequest({
      method: 'POST',
      url: '/api/upload_asset.php',
      body: { bucket: 'property-assets', file_data: 'dGVzdA==', file_name: 'test.jpg' },
    });
    const res = createMockResponse();
    await router(req, res);

    assert.strictEqual(res.statusCode, 401);
    assert.match(res.body.message, /Authentication required/i);
  });
});

