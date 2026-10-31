import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';

const apiBase = 'https://api.jamendo.com/v3.0/tracks/';
const rateWindowMs = 60_000;
const maxRequestsPerWindow = 60;
const cacheWindowMs = 30_000;
const maxCachedQueries = 500;

function json(response, status, body, headers = {}) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
    ...headers,
  });
  response.end(JSON.stringify(body));
}

function safeAudioUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' &&
      (url.hostname === 'jamendo.com' || url.hostname.endsWith('.jamendo.com'))
      ? url.toString()
      : null;
  } catch {
    return null;
  }
}

function validTrackId(value) {
  return /^\d{1,16}$/.test(value);
}

export function createMusicServer({
  env = process.env,
  fetchImpl = fetch,
  requestLimit = maxRequestsPerWindow,
} = {}) {
  const requests = new Map();
  const cache = new Map();
  const allowedOrigins = new Set(
    (env.CORS_ORIGINS ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );

  async function queryJamendo(parameters) {
    if (!env.JAMENDO_CLIENT_ID || env.JAMENDO_COMMERCIAL_LICENSE_CONFIRMED !== 'true') {
      const error = new Error('Jamendo commercial API access is not configured.');
      error.statusCode = 503;
      throw error;
    }
    const key = JSON.stringify(Object.entries(parameters).sort(([a], [b]) => a.localeCompare(b)));
    const cached = cache.get(key);
    if (cached && cached.expiresAt > Date.now()) return cached.rows;
    if (cached) cache.delete(key);

    const url = new URL(apiBase);
    url.search = new URLSearchParams({
      client_id: env.JAMENDO_CLIENT_ID,
      format: 'json',
      include: 'licenses',
      audioformat: 'mp32',
      type: 'single albumtrack',
      ...parameters,
    }).toString();

    const upstream = await fetchImpl(url, {
      headers: { accept: 'application/json' },
      signal: AbortSignal.timeout(8_000),
    });
    if (!upstream.ok) {
      const error = new Error('The music catalog could not complete the request.');
      error.statusCode = 502;
      throw error;
    }
    const payload = await upstream.json();
    if (payload?.headers?.status !== 'success' || !Array.isArray(payload.results)) {
      const error = new Error('The music catalog returned an invalid response.');
      error.statusCode = 502;
      throw error;
    }
    if (cache.size >= maxCachedQueries) {
      const oldestKey = cache.keys().next().value;
      if (oldestKey != null) cache.delete(oldestKey);
    }
    cache.set(key, { rows: payload.results, expiresAt: Date.now() + cacheWindowMs });
    return payload.results;
  }

  return createServer(async (request, response) => {
    const origin = request.headers.origin;
    const corsHeaders = {};
    if (origin) {
      if (!allowedOrigins.has(origin)) {
        json(response, 403, { error: 'Origin is not allowed.' });
        return;
      }
      corsHeaders['access-control-allow-origin'] = origin;
      corsHeaders.vary = 'Origin';
    }
    if (request.method === 'OPTIONS') {
      response.writeHead(204, {
        ...corsHeaders,
        'access-control-allow-methods': 'GET, OPTIONS',
        'access-control-allow-headers': 'content-type',
        'access-control-max-age': '600',
      });
      response.end();
      return;
    }
    if (request.method !== 'GET') {
      json(response, 405, { error: 'Method not allowed.' }, corsHeaders);
      return;
    }

    const now = Date.now();
    const client = request.socket.remoteAddress ?? 'unknown';
    const rate = requests.get(client);
    if (!rate || now - rate.startedAt >= rateWindowMs) {
      requests.set(client, { startedAt: now, count: 1 });
    } else if (++rate.count > requestLimit) {
      json(response, 429, { error: 'Too many catalog requests. Try again shortly.' }, corsHeaders);
      return;
    }
    if (requests.size > 2000) {
      for (const [key, value] of requests) {
        if (now - value.startedAt >= rateWindowMs) requests.delete(key);
      }
    }

    const url = new URL(request.url, 'http://localhost');
    if (url.pathname === '/health') {
      json(response, 200, {
        status: 'ok',
        musicConfigured: Boolean(
          env.JAMENDO_CLIENT_ID && env.JAMENDO_COMMERCIAL_LICENSE_CONFIRMED === 'true',
        ),
      }, corsHeaders);
      return;
    }

    try {
      if (url.pathname === '/v1/music/search') {
        const query = (url.searchParams.get('q') ?? '').trim();
        if (query.length > 120 || /[\u0000-\u001f\u007f]/u.test(query)) {
          json(response, 400, { error: 'Search text is too long.' }, corsHeaders);
          return;
        }
        const pageText = url.searchParams.get('page') ?? '1';
        const limitText = url.searchParams.get('limit') ?? '30';
        if (!/^\d+$/u.test(pageText) || !/^\d+$/u.test(limitText)) {
          json(response, 400, { error: 'Invalid page or result limit.' }, corsHeaders);
          return;
        }
        const page = Number(pageText);
        const limit = Number(limitText);
        if (!Number.isInteger(page) || page < 1 || page > 1000 ||
            !Number.isInteger(limit) || limit < 1 || limit > 50) {
          json(response, 400, { error: 'Invalid page or result limit.' }, corsHeaders);
          return;
        }

        const parameters = {
          limit: String(limit),
          offset: String((page - 1) * limit),
        };
        if (query) parameters.search = query;
        else parameters.order = 'popularity_week_desc';
        const rows = await queryJamendo(parameters);
        const results = rows.flatMap((row) => {
          const audio = safeAudioUrl(row?.audio);
          if (!audio || !row?.id || !row?.name) return [];
          return [{
            id: String(row.id),
            name: String(row.name),
            artist_name: String(row.artist_name ?? 'Unknown artist'),
            album_name: String(row.album_name ?? ''),
            duration: row.duration,
            audio,
            license_ccurl: row.license_ccurl,
            image: row.image ?? row.album_image,
            shareurl: row.shareurl,
          }];
        });
        json(response, 200, { results }, corsHeaders);
        return;
      }

      const streamMatch = url.pathname.match(/^\/v1\/music\/stream\/([^/]+)$/);
      if (streamMatch) {
        const trackId = decodeURIComponent(streamMatch[1]);
        if (!validTrackId(trackId)) {
          json(response, 400, { error: 'Invalid track ID.' }, corsHeaders);
          return;
        }
        const rows = await queryJamendo({ id: trackId, limit: '1' });
        const streamUrl = safeAudioUrl(rows[0]?.audio);
        if (!streamUrl) {
          json(response, 404, { error: 'Track stream is not available.' }, corsHeaders);
          return;
        }
        json(response, 200, { url: streamUrl }, corsHeaders);
        return;
      }

      json(response, 404, { error: 'Not found.' }, corsHeaders);
    } catch (error) {
      const status = Number.isInteger(error.statusCode) ? error.statusCode : 502;
      json(response, status, {
        error: status === 503
          ? 'Jamendo commercial API access is not configured.'
          : status === 502
            ? 'The music catalog is temporarily unavailable.'
            : 'The music request failed.',
      }, corsHeaders);
    }
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const server = createMusicServer();
  const port = Number.parseInt(process.env.PORT ?? '8787', 10);
  const host = process.env.HOST ?? '127.0.0.1';
  server.listen(port, host, () => {
    process.stdout.write(`NM VYBE music API listening on http://${host}:${port}\n`);
  });
}
