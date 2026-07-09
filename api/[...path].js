const FALLBACK_BACKEND_URL = 'https://arrealestateapp-muazz.et.r.appspot.com';

function getBackendBaseUrl() {
  return process.env.BACKEND_URL || FALLBACK_BACKEND_URL;
}

function buildTargetUrl(requestUrl) {
  const target = new URL(requestUrl, 'http://localhost');
  const path = target.pathname.replace(/^\/api\/?/, '');
  const backendBase = getBackendBaseUrl().replace(/\/$/, '');
  return `${backendBase}/${path}${target.search}`;
}

async function readBody(request) {
  const contentType = request.headers['content-type'] || '';

  if (request.method === 'GET' || request.method === 'HEAD') {
    return undefined;
  }

  if (contentType.includes('application/json')) {
    const text = await readStream(request);
    return text ? JSON.stringify(JSON.parse(text)) : undefined;
  }

  if (contentType.includes('application/x-www-form-urlencoded') || contentType.includes('multipart/form-data')) {
    return readStream(request);
  }

  return readStream(request);
}

function readStream(request) {
  return new Promise((resolve, reject) => {
    let data = '';

    request.on('data', (chunk) => {
      data += chunk;
    });

    request.on('end', () => resolve(data));
    request.on('error', reject);
  });
}

function corsHeaders(request) {
  const origin = request.headers.origin || '*';

  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': request.headers['access-control-request-headers'] || 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

module.exports = async function handler(request, response) {
  if (request.method === 'OPTIONS') {
    Object.entries(corsHeaders(request)).forEach(([key, value]) => response.setHeader(key, value));
    response.setHeader('Allow', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
    return response.status(204).end();
  }

  const targetUrl = buildTargetUrl(request.url);
  const body = await readBody(request);

  const headers = {
    ...corsHeaders(request),
  };

  const contentType = request.headers['content-type'];
  if (contentType) {
    headers['Content-Type'] = contentType;
  }

  try {
    const upstreamResponse = await fetch(targetUrl, {
      method: request.method,
      headers,
      body,
    });

    const responseHeaders = corsHeaders(request);
    const upstreamContentType = upstreamResponse.headers.get('content-type');
    if (upstreamContentType) {
      responseHeaders['Content-Type'] = upstreamContentType;
    }

    response.status(upstreamResponse.status);
    Object.entries(responseHeaders).forEach(([key, value]) => response.setHeader(key, value));

    const upstreamBody = await upstreamResponse.text();
    return response.send(upstreamBody);
  } catch (error) {
    console.error('API proxy failed:', error);
    Object.entries(corsHeaders(request)).forEach(([key, value]) => response.setHeader(key, value));
    return response.status(502).json({ message: 'Proxy request failed', error: String(error) });
  }
}