import assert from 'node:assert/strict';
import { after, test } from 'node:test';
import { createMusicServer } from './server.mjs';

const env = {
  JAMENDO_CLIENT_ID: 'server-side-test-id',
  JAMENDO_COMMERCIAL_LICENSE_CONFIRMED: 'true',
};
const server = createMusicServer({
  env,
  fetchImpl: async (input) => {
    const url = new URL(input);
    assert.equal(url.searchParams.get('client_id'), env.JAMENDO_CLIENT_ID);
    const row = {
      id: url.searchParams.get('id') ?? '42',
      name: 'Example track',
      artist_name: 'Example artist',
      duration: '180',
      audio: 'https://prod-1.storage.jamendo.com/?trackid=42',
      audiodownload: 'https://prod-1.storage.jamendo.com/download/42.mp3',
      audiodownload_allowed: true,
      license_ccurl: 'https://creativecommons.org/licenses/by/4.0/',
      image: 'https://usercontent.jamendo.com/cover.jpg',
      shareurl: 'https://www.jamendo.com/track/42',
    };
    return new Response(JSON.stringify({
      headers: { status: 'success' },
      results: [row],
    }), { status: 200, headers: { 'content-type': 'application/json' } });
  },
});
server.listen(0, '127.0.0.1');
await new Promise((resolve) => server.once('listening', resolve));
const baseUrl = `http://127.0.0.1:${server.address().port}`;
after(() => new Promise((resolve) => server.close(resolve)));

test('search keeps Jamendo credentials server-side and returns safe track data', async () => {
  const response = await fetch(`${baseUrl}/v1/music/search?q=ambient&page=2&limit=10`);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const payload = await response.json();
  assert.equal(payload.results[0].id, '42');
  assert.equal(payload.results[0].audio, 'https://prod-1.storage.jamendo.com/?trackid=42');
  assert.equal('audiodownload_allowed' in payload.results[0], false);
  assert.equal('audiodownload' in payload.results[0], false);
  assert.equal(JSON.stringify(payload).includes(env.JAMENDO_CLIENT_ID), false);
});

test('stream resolver returns an allowlisted HTTPS Jamendo URL', async () => {
  const response = await fetch(`${baseUrl}/v1/music/stream/42`);
  assert.equal(response.status, 200);
  assert.equal((await response.json()).url, 'https://prod-1.storage.jamendo.com/?trackid=42');
});

test('rejects invalid paging and track IDs', async () => {
  assert.equal((await fetch(`${baseUrl}/v1/music/search?page=0`)).status, 400);
  assert.equal((await fetch(`${baseUrl}/v1/music/stream/../admin`)).status, 404);
});

test('fails closed until commercial Jamendo approval is configured', async () => {
  const guarded = createMusicServer({ env: { JAMENDO_CLIENT_ID: 'present' } });
  guarded.listen(0, '127.0.0.1');
  await new Promise((resolve) => guarded.once('listening', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${guarded.address().port}/v1/music/search`);
    assert.equal(response.status, 503);
  } finally {
    await new Promise((resolve) => guarded.close(resolve));
  }
});

test('rejects overlong, control-character, malformed and oversized search input', async () => {
  assert.equal((await fetch(`${baseUrl}/v1/music/search?q=${'x'.repeat(121)}`)).status, 400);
  assert.equal((await fetch(`${baseUrl}/v1/music/search?q=${encodeURIComponent('bad\nquery')}`)).status, 400);
  assert.equal((await fetch(`${baseUrl}/v1/music/search?page=1x`)).status, 400);
  assert.equal((await fetch(`${baseUrl}/v1/music/search?limit=51`)).status, 400);
});

test('returns a clean error on an upstream failure', async () => {
  const failing = createMusicServer({
    env,
    fetchImpl: async () => { throw new Error('private upstream detail'); },
  });
  failing.listen(0, '127.0.0.1');
  await new Promise((resolve) => failing.once('listening', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${failing.address().port}/v1/music/search?q=test`);
    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: 'The music catalog is temporarily unavailable.' });
  } finally {
    await new Promise((resolve) => failing.close(resolve));
  }
});

test('rate limits excessive requests by client address', async () => {
  const limited = createMusicServer({ env, requestLimit: 2 });
  limited.listen(0, '127.0.0.1');
  await new Promise((resolve) => limited.once('listening', resolve));
  try {
    const url = `http://127.0.0.1:${limited.address().port}/health`;
    assert.equal((await fetch(url)).status, 200);
    assert.equal((await fetch(url)).status, 200);
    const blocked = await fetch(url);
    assert.equal(blocked.status, 429);
    assert.deepEqual(await blocked.json(), { error: 'Too many catalog requests. Try again shortly.' });
  } finally {
    await new Promise((resolve) => limited.close(resolve));
  }
});

test('caches repeated search requests briefly', async () => {
  let calls = 0;
  const cached = createMusicServer({
    env,
    fetchImpl: async () => {
      calls++;
      return new Response(JSON.stringify({ headers: { status: 'success' }, results: [] }), { status: 200 });
    },
  });
  cached.listen(0, '127.0.0.1');
  await new Promise((resolve) => cached.once('listening', resolve));
  try {
    const url = `http://127.0.0.1:${cached.address().port}/v1/music/search?q=ambient`;
    assert.equal((await fetch(url)).status, 200);
    assert.equal((await fetch(url)).status, 200);
    assert.equal(calls, 1);
  } finally {
    await new Promise((resolve) => cached.close(resolve));
  }
});

test('empty search requests popular featured-style tracks without unsupported filters', async () => {
  let upstreamUrl;
  const catalog = createMusicServer({
    env,
    fetchImpl: async (input) => {
      upstreamUrl = new URL(input);
      return new Response(JSON.stringify({ headers: { status: 'success' }, results: [] }), { status: 200 });
    },
  });
  catalog.listen(0, '127.0.0.1');
  await new Promise((resolve) => catalog.once('listening', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${catalog.address().port}/v1/music/search?limit=3`);
    assert.equal(response.status, 200);
    assert.equal(upstreamUrl.searchParams.get('order'), 'popularity_week_desc');
    assert.equal(upstreamUrl.searchParams.has('featured'), false);
  } finally {
    await new Promise((resolve) => catalog.close(resolve));
  }
});
