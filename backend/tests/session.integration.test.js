// Real logout / session revocation, and the indexes that keep list screens fast.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const testDbName = `prm393_session_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'session-isolated-integration-tests-secret-0123456789';
process.env.NODE_ENV = 'test';
const db = require('../src/config/database');
const { ensureQueryIndexes } = require('../src/config/query_indexes');
const { ensureMember1Indexes } = require('../src/config/member1_indexes');
const app = require('../src/app');
let server;
let base;

async function call(tokenValue, method, path, body) {
  const headers = {};
  if (tokenValue) headers.Authorization = `Bearer ${tokenValue}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${base}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  return { status: response.status, ...await response.json() };
}
const login = async (phone, password = 'abcd1234') =>
  (await call(null, 'POST', '/auth/login', { phone, password })).data.token;

before(async () => {
  await db.connectDb();
  await ensureQueryIndexes();
  await ensureMember1Indexes();
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});
after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName) await db.getDb().dropDatabase();
  await db.closePool();
});

test('logout revokes the token on the server, not only on the device', async () => {
  const reg = await call(null, 'POST', '/auth/register', { full_name: 'Una', phone: '0977000001', password: 'abcd1234' });
  const phone1 = reg.data.token;
  const phone2 = await login('0977000001'); // a second device
  assert.equal((await call(phone1, 'GET', '/auth/me')).status, 200);
  assert.equal((await call(phone2, 'GET', '/auth/me')).status, 200);

  assert.equal((await call(phone1, 'POST', '/auth/logout')).status, 200);
  assert.equal((await call(phone1, 'GET', '/auth/me')).status, 401, 'the logged-out token is dead');
  assert.equal((await call(phone1, 'GET', '/feed')).status, 401);
  assert.equal((await call(phone2, 'GET', '/auth/me')).status, 401, 'logout ends all sessions');

  const fresh = await login('0977000001');
  assert.equal((await call(fresh, 'GET', '/auth/me')).status, 200, 'logging in again works');
});

test('password change signs out other devices and returns a fresh token', async () => {
  await call(null, 'POST', '/auth/register', { full_name: 'Vu', phone: '0977000002', password: 'abcd1234' });
  const thisDevice = await login('0977000002');
  const otherDevice = await login('0977000002');

  const changed = await call(thisDevice, 'POST', '/auth/change-password', { current_password: 'abcd1234', new_password: 'newpass99' });
  assert.equal(changed.status, 200);
  assert.ok(changed.data.token, 'a new token is returned');

  assert.equal((await call(thisDevice, 'GET', '/auth/me')).status, 401, 'old token of this device is revoked');
  assert.equal((await call(otherDevice, 'GET', '/auth/me')).status, 401, 'other device is signed out');
  assert.equal((await call(changed.data.token, 'GET', '/auth/me')).status, 200, 'fresh token works');
  assert.equal((await call(null, 'POST', '/auth/login', { phone: '0977000002', password: 'newpass99' })).status, 200);
});

test('responses never expose token_version or the password hash', async () => {
  const reg = await call(null, 'POST', '/auth/register', { full_name: 'Wen', phone: '0977000003', password: 'abcd1234' });
  assert.equal(reg.data.user.token_version, undefined);
  assert.equal(reg.data.user.password_hash, undefined);
  const logged = await call(null, 'POST', '/auth/login', { phone: '0977000003', password: 'abcd1234' });
  assert.equal(logged.data.user.token_version, undefined);
  const me = await call(logged.data.token, 'GET', '/auth/me');
  assert.equal(me.data.user.token_version, undefined);
  assert.equal(me.data.user.password_hash, undefined);
});

test('list queries are served by indexes (no collection scans)', async () => {
  const users = (await call(null, 'POST', '/auth/register', { full_name: 'Xi', phone: '0977000004', password: 'abcd1234' })).data.user.id;
  await db.getCollection('Post').insertMany(Array.from({ length: 30 }, (_, i) => ({
    _id: `p${i}`, id: `p${i}`, author_id: i % 2 ? users : 'other', content: 'x', created_at: new Date(i * 1000),
  })));
  await db.getCollection('Reaction').insertMany(Array.from({ length: 30 }, (_, i) => ({
    post_id: `p${i}`, user_id: i % 2 ? users : 'other', created_at: new Date(i * 1000),
  })));
  await db.getCollection('SavedPost').insertMany(Array.from({ length: 30 }, (_, i) => ({
    post_id: `p${i}`, user_id: i % 2 ? users : 'other', created_at: new Date(i * 1000),
  })));
  const stage = async (collection, filter, sort) => {
    const plan = await db.getCollection(collection).find(filter).sort(sort).explain('queryPlanner');
    return JSON.stringify(plan.queryPlanner.winningPlan);
  };
  assert.match(await stage('Post', { author_id: users }, { created_at: -1 }), /IXSCAN/, 'My Posts / profile posts');
  assert.match(await stage('Reaction', { user_id: users }, { created_at: -1 }), /IXSCAN/, 'Liked Posts');
  assert.match(await stage('SavedPost', { user_id: users }, { created_at: -1 }), /IXSCAN/, 'Saved Posts');
  assert.doesNotMatch(await stage('Post', { author_id: users }, { created_at: -1 }), /COLLSCAN/);
});

test('lists beyond 100 rows are reachable page by page (comments)', async () => {
  const token = (await call(null, 'POST', '/auth/register', { full_name: 'Yan', phone: '0977000005', password: 'abcd1234' })).data;
  await db.getCollection('Post').insertOne({ _id: 'big', id: 'big', author_id: token.user.id, content: 'busy post', audience: 'public', created_at: new Date() });
  await db.getCollection('Comment').insertMany(Array.from({ length: 130 }, (_, i) => ({
    id: `c${i}`, post_id: 'big', author_id: token.user.id, content: `c${i}`, created_at: new Date(i * 1000),
  })));
  const first = await call(token.token, 'GET', '/posts/big/comments?page=1&limit=100');
  assert.equal(first.data.length, 100);
  assert.equal(first.pagination.has_more, true);
  const second = await call(token.token, 'GET', '/posts/big/comments?page=2&limit=100');
  assert.equal(second.data.length, 30);
  assert.equal(second.pagination.has_more, false);
  assert.equal(second.data[29].content, 'c129', 'oldest first, nothing skipped');
});
