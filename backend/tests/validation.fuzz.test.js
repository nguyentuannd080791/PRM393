// Sends hostile/invalid input to every endpoint. Rule: never a 5xx, never a stack trace,
// and nothing hostile may be stored. Uses its own throwaway database.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const testDbName = `prm393_fuzz_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'fuzz-isolated-integration-tests-secret-0123456789';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const app = require('../src/app');
let server;
let base;
const bad5xx = [];
function report() {
  // Group by endpoint + message so a failure list stays readable.
  const groups = new Map();
  for (const line of bad5xx) {
    const key = line.replace(/ body=.*? -> /, ' -> ').replace(/\/(?:[^/ ]{0,60})(?= ->)/, '');
    groups.set(key, (groups.get(key) || 0) + 1);
  }
  assert.deepEqual([...groups].map(([k, n]) => `${n}x ${k}`), []);
}

const token = id => jwt.sign({ userId: id }, process.env.JWT_SECRET);
async function call(user, method, path, body, rawBody) {
  const headers = {};
  if (user) headers.Authorization = `Bearer ${token(user)}`;
  if (body !== undefined || rawBody !== undefined) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${base}${path}`, {
    method, headers, body: rawBody !== undefined ? rawBody : body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let json = null;
  try { json = JSON.parse(text); } catch { /* non-JSON */ }
  if (response.status >= 500) bad5xx.push(`${method} ${path} body=${String(rawBody ?? JSON.stringify(body)).slice(0, 80)} -> ${response.status} ${text.slice(0, 120)}`);
  if (/\bat .*\.js:\d+/.test(text)) bad5xx.push(`${method} ${path} leaked a stack trace`);
  return { status: response.status, json };
}

// Values that commonly break handlers.
const HOSTILE = [
  null, 0, -1, 1.5, true, [], ['a'], {}, { $ne: null }, { $gt: '' }, { $regex: '.*' }, '', '   ', ' ',
  'x'.repeat(200000), '<script>alert(1)</script>', '😀'.repeat(50), '\u0000', "' OR '1'='1", '../../etc/passwd',
  '$where', { __proto__: { x: 1 } },
];

before(async () => {
  await db.connectDb();
  await db.getCollection('User').insertMany(['alice', 'bob'].map(id =>
    ({ _id: id, id, full_name: id.toUpperCase(), password_hash: 'x', created_at: new Date() })));
  await db.getCollection('Post').insertOne({ _id: 'p1', id: 'p1', author_id: 'bob', content: 'hello', audience: 'public', created_at: new Date() });
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});

after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName) await db.getDb().dropDatabase();
  await db.closePool();
});

test('every JSON body field survives hostile values without a 5xx', async () => {
  const targets = [
    ['POST', '/auth/register', null, ['full_name', 'phone', 'email', 'password', 'birthday', 'bio', 'gender', 'city', 'workplace']],
    ['POST', '/auth/login', null, ['phone', 'email', 'identifier', 'password']],
    ['POST', '/auth/change-password', 'alice', ['current_password', 'new_password']],
    ['POST', '/posts', 'alice', ['content', 'audience']],
    ['PUT', '/posts/p1', 'bob', ['content', 'audience']],
    ['POST', '/posts/p1/comments', 'alice', ['content']],
    ['PUT', '/users/profile', 'alice', ['full_name', 'bio']],
    ['POST', '/friends/requests', 'alice', ['receiver_id']],
  ];
  for (const [method, path, user, fields] of targets) {
    const valid = { full_name: 'Ok Name', phone: '0912345678', password: 'abcd1234', content: 'ok', current_password: 'abcd1234', new_password: 'newpass99', receiver_id: 'bob', audience: 'public' };
    for (const field of fields) {
      for (const value of HOSTILE) {
        await call(user, method, path, { ...valid, [field]: value });
      }
    }
    // Whole body hostile
    for (const raw of ['null', '[]', '"str"', '123', '{', '{"a":', '', '\u0000']) await call(user, method, path, undefined, raw);
  }
  report();
});

test('every path/query parameter survives hostile values without a 5xx', async () => {
  const ids = ['%00', '..%2F..', 'x'.repeat(5000), '%24ne', '%7B%7D', 'null', 'undefined', '"', '%E0%A4%A', 'me', ' ', '*'];
  const queries = ['', '?page=0', '?page=-1', '?page=abc', '?page=99999999999', '?limit=0', '?limit=1000', '?limit=1.5', '?limit=%00',
    '?page[$ne]=1', '?limit[]=1&limit[]=2', '?q=', '?q[$ne]=a', '?q=a&q=b', `?q=${'x'.repeat(10000)}`, '?q=.*', '?q=(((', '?q=%5C'];
  const pathTemplates = [
    ['GET', '/feed/posts/ID', 'alice'], ['GET', '/feed/posts/ID/likes', 'alice'], ['PUT', '/feed/posts/ID/like', 'alice'],
    ['DELETE', '/feed/posts/ID/like', 'alice'], ['PUT', '/feed/posts/ID/save', 'alice'], ['DELETE', '/feed/posts/ID/save', 'alice'],
    ['GET', '/posts/ID/comments', 'alice'], ['DELETE', '/comments/ID', 'alice'], ['GET', '/posts/ID/insights', 'alice'],
    ['PUT', '/posts/ID', 'alice'], ['DELETE', '/posts/ID', 'alice'], ['GET', '/posts/users/ID', 'alice'],
    ['GET', '/users/ID', 'alice'], ['GET', '/users/ID/posts', 'alice'], ['GET', '/friends/status/ID', 'alice'],
    ['PATCH', '/friends/requests/ID/accept', 'alice'], ['PATCH', '/friends/requests/ID/decline', 'alice'],
    ['PATCH', '/friends/requests/ID/cancel', 'alice'], ['PATCH', '/notifications/ID/read', 'alice'],
  ];
  for (const [method, template, user] of pathTemplates) {
    for (const id of ids) await call(user, method, template.replace('ID', id), method === 'PUT' ? {} : undefined);
  }
  const listPaths = ['/feed', '/notifications', '/friends', '/friends/requests/received', '/friends/requests/sent',
    '/me/liked-posts', '/me/saved-posts', '/search/users', '/search/posts', '/posts/p1/comments', '/users/alice/posts', '/posts/users/alice'];
  for (const path of listPaths) for (const q of queries) await call('alice', 'GET', `${path}${q}`);
  report();
});

test('malformed or forged credentials are 401, not 5xx', async () => {
  const auth = ['', 'Bearer', 'Bearer ', 'Bearer x', 'Bearer a.b.c', 'Basic abc', 'bearer ' + 'x'.repeat(10000), 'Bearer null'];
  for (const h of auth) {
    const response = await fetch(`${base}/feed`, { headers: h ? { Authorization: h } : {} });
    assert.equal(response.status, 401, h.slice(0, 20));
  }
  // alg:none forgery must be rejected
  const none = `${Buffer.from('{"alg":"none","typ":"JWT"}').toString('base64url')}.${Buffer.from('{"userId":"alice"}').toString('base64url')}.`;
  assert.equal((await fetch(`${base}/feed`, { headers: { Authorization: `Bearer ${none}` } })).status, 401);
  // token signed with another secret
  const wrong = jwt.sign({ userId: 'alice' }, 'some-other-secret-some-other-secret-1234');
  assert.equal((await fetch(`${base}/feed`, { headers: { Authorization: `Bearer ${wrong}` } })).status, 401);
  report();
});

test('hostile content is never stored as an operator object', async () => {
  const created = await call('alice', 'POST', '/posts', { content: { $ne: null } });
  assert.equal(created.status, 400);
  const rows = await db.getCollection('Post').find({ author_id: 'alice' }).toArray();
  assert.ok(rows.every(r => typeof r.content === 'string'));
  const login = await call(null, 'POST', '/auth/login', { phone: { $ne: null }, password: { $ne: null } });
  assert.ok(login.status >= 400 && login.status < 500);
});
