/**
 * /api/image-proxy.js
 *
 * Vercel serverless image proxy.
 * Fetches images server-side (no browser CORS restrictions) and streams
 * them back with Access-Control-Allow-Origin: * so Flutter Web CanvasKit
 * can decode them via fetch().
 *
 * Usage: GET /api/image-proxy?url=<url-encoded-image-url>
 *
 * Allowed origin domains (allowlist to prevent open-proxy abuse):
 *   - *.supabase.co  (Supabase Storage)
 *   - images.unsplash.com / *.unsplash.com  (Unsplash CDN)
 *   - cdn.supabase.com  (Supabase CDN edge)
 */

const ALLOWED_HOSTNAMES = [
  'images.unsplash.com',
  'cdn.unsplash.com',
  'plus.unsplash.com',
];

const ALLOWED_HOSTNAME_SUFFIXES = [
  '.supabase.co',
  '.supabase.com',
];

// Max image size to proxy: 20 MB
const MAX_IMAGE_BYTES = 20 * 1024 * 1024;

// Cache TTL for proxied images (1 hour at CDN, 10 min at browser)
const CACHE_CONTROL = 'public, max-age=600, s-maxage=3600, stale-while-revalidate=86400';

function isAllowedUrl(urlString) {
  try {
    const parsed = new URL(urlString);
    if (parsed.protocol !== 'https:') return false;

    const host = parsed.hostname.toLowerCase();

    if (ALLOWED_HOSTNAMES.includes(host)) return true;

    for (const suffix of ALLOWED_HOSTNAME_SUFFIXES) {
      if (host.endsWith(suffix)) return true;
    }

    return false;
  } catch {
    return false;
  }
}

module.exports = async function handler(req, res) {
  // CORS preflight
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Range');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const rawUrl = req.query && req.query.url;
  if (!rawUrl) {
    return res.status(400).json({ error: 'Missing url parameter' });
  }

  let decodedUrl;
  try {
    decodedUrl = decodeURIComponent(rawUrl);
  } catch {
    return res.status(400).json({ error: 'Invalid url encoding' });
  }

  if (!isAllowedUrl(decodedUrl)) {
    return res.status(403).json({ error: 'URL origin not allowed' });
  }

  // Normalize Unsplash URLs to JPEG to prevent AVIF decoding failure on CanvasKit
  if (decodedUrl.includes('images.unsplash.com')) {
    try {
      const u = new URL(decodedUrl);
      u.searchParams.delete('auto');
      u.searchParams.set('fm', 'jpg');
      decodedUrl = u.toString();
    } catch {
      decodedUrl = decodedUrl.replace(/auto=format/g, 'fm=jpg');
    }
  }

  let upstream;
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000); // 15s timeout

    upstream = await fetch(decodedUrl, {
      method: req.method,
      signal: controller.signal,
      headers: {
        // Benign user agent; exclude avif to avoid CanvasKit Web decode failures
        'User-Agent': 'Vizare-ImageProxy/1.0',
        'Accept': 'image/jpeg,image/png,image/webp,image/*,*/*;q=0.8',
      },
    });

    clearTimeout(timeoutId);
  } catch (err) {
    if (err.name === 'AbortError') {
      return res.status(504).json({ error: 'Upstream request timed out' });
    }
    return res.status(502).json({ error: 'Failed to fetch upstream image' });
  }

  if (!upstream.ok) {
    return res.status(upstream.status).json({
      error: `Upstream returned ${upstream.status}`,
    });
  }

  // Validate content-type is an image
  const contentType = upstream.headers.get('content-type') || '';
  if (!contentType.startsWith('image/')) {
    return res.status(400).json({ error: 'Upstream response is not an image' });
  }

  // Read body with size limit
  const arrayBuffer = await upstream.arrayBuffer();
  if (arrayBuffer.byteLength > MAX_IMAGE_BYTES) {
    return res.status(413).json({ error: 'Image too large' });
  }

  // Forward the image
  res.setHeader('Content-Type', contentType);
  res.setHeader('Content-Length', arrayBuffer.byteLength);
  res.setHeader('Cache-Control', CACHE_CONTROL);
  res.setHeader('X-Proxied-For', 'vizare-image-proxy');
  // Propagate ETag if present for browser-side caching
  const etag = upstream.headers.get('etag');
  if (etag) res.setHeader('ETag', etag);

  return res.status(200).send(Buffer.from(arrayBuffer));
};
