const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert');
const { EventEmitter } = require('node:events');

const router = require('../api/supabase-router');
const pathEntrypoint = require('../api/[...path]');

function createMockRequest({ method = 'GET', url = '/api/client_config.php', headers = {}, body = null }) {
  const req = new EventEmitter();
  req.method = method;
  req.url = url;
  req.headers = { host: 'localhost:3000', ...headers };
  req.body = body;
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
        'access-control-request-headers': 'Content-Type, Authorization',
      },
    });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 204);
    assert.strictEqual(res.headers['access-control-allow-origin'], 'https://vizare.app');
    assert.strictEqual(res.headers['access-control-allow-methods'], 'GET,POST,OPTIONS');
    assert.strictEqual(res.headers['access-control-allow-headers'], 'Content-Type, Authorization');
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
    process.env.SUPABASE_PUBLISHABLE_KEY = 'mock-anon-key-xyz';
    process.env.GOOGLE_MAPS_API_KEY = 'mock-google-maps-key-123';
    process.env.GOOGLE_OAUTH_CLIENT_ID = 'mock-google-client-id-abc';

    const req = createMockRequest({ method: 'GET', url: '/api/client_config.php' });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 200);
    assert.deepStrictEqual(res.body, {
      supabase_url: 'https://mock.supabase.co',
      supabase_publishable_key: 'mock-anon-key-xyz',
      google_maps_api_key: 'mock-google-maps-key-123',
      google_oauth_client_id: 'mock-google-client-id-abc',
    });
  });

  test('returns 503 SERVER_CONFIGURATION_ERROR when Supabase env vars are missing', async () => {
    delete process.env.SUPABASE_URL;
    delete process.env.SUPABASE_SERVICE_ROLE_KEY;
    delete process.env.SUPABASE_ANON_KEY;

    const req = createMockRequest({ method: 'GET', url: '/api/get_all_listings.php' });
    const res = createMockResponse();

    await router(req, res);

    assert.strictEqual(res.statusCode, 503);
    assert.match(res.body.message, /The API is not configured/);
  });
});
