// Unfriend: DELETE /api/friends/:userId. Own throwaway database.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const testDbName = `prm393_unfriend_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'unfriend-isolated-integration-tests-secret-0123456789';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const { ensureMember4Indexes } = require('../src/config/member4_indexes');
const app = require('../src/app');
let server;
let base;

const token = id => jwt.sign({ userId: id }, process.env.JWT_SECRET);
async function call(user, method, path, body) {
  const headers = user ? { Authorization: `Bearer ${token(user)}` } : {};
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${base}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  return { status: response.status, ...await response.json() };
}
const befriend = async (a, b) => {
  const sent = await call(a, 'POST', '/friends/requests', { receiver_id: b });
  assert.equal(sent.status, 201);
  assert.equal((await call(b, 'PATCH', `/friends/requests/${sent.data.id}/accept`)).status, 200);
};

before(async () => {
  await db.connectDb();
  await ensureMember4Indexes();
  await db.getCollection('User').insertMany(['alice', 'bob', 'cara'].map(id =>
    ({ _id: id, id, full_name: id.toUpperCase(), password_hash: 'x' })));
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});
after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName) await db.getDb().dropDatabase();
  await db.closePool();
});

test('rejects bad input and strangers', async () => {
  assert.equal((await call(null, 'DELETE', '/friends/bob')).status, 401);
  assert.equal((await call('alice', 'DELETE', '/friends/alice')).status, 400, 'self');
  assert.equal((await call('alice', 'DELETE', '/friends/%00')).status, 400, 'bad id');
  assert.equal((await call('alice', 'DELETE', '/friends/nobody')).status, 404, 'unknown user');
  assert.equal((await call('alice', 'DELETE', '/friends/bob')).status, 404, 'not friends');
});

test('either friend can unfriend; relationship, lists and visibility update', async () => {
  await befriend('alice', 'bob');
  await db.getCollection('Post').insertOne({
    _id: 'fp', id: 'fp', author_id: 'bob', content: 'friends only', audience: 'friends', created_at: new Date(),
  });
  assert.equal((await call('alice', 'GET', '/friends/status/bob')).data.status, 'friends');
  assert.equal((await call('alice', 'GET', '/feed/posts/fp')).status, 200);

  const removed = await call('alice', 'DELETE', '/friends/bob');
  assert.equal(removed.status, 200);
  assert.equal(removed.data.status, 'none');

  assert.equal((await call('alice', 'GET', '/friends/status/bob')).data.status, 'none');
  assert.equal((await call('bob', 'GET', '/friends/status/alice')).data.status, 'none', 'both sides');
  assert.equal((await call('alice', 'GET', '/friends')).data.length, 0);
  assert.equal((await call('bob', 'GET', '/friends')).data.length, 0);
  assert.equal((await call('alice', 'GET', '/feed/posts/fp')).status, 404, 'ex-friend loses access to friends-only posts');
  assert.equal((await call('alice', 'DELETE', '/friends/bob')).status, 404, 'second unfriend is a clean 404');
});

test('the other side can unfriend too, and a new request works afterwards', async () => {
  await befriend('alice', 'bob');
  assert.equal((await call('bob', 'DELETE', '/friends/alice')).status, 200);
  const again = await call('bob', 'POST', '/friends/requests', { receiver_id: 'alice' });
  assert.equal(again.status, 201);
  assert.equal((await call('alice', 'GET', '/friends/status/bob')).data.status, 'pending_received');
});

test('a third person cannot end someone else friendship; pending requests are not unfriendable', async () => {
  await db.getCollection('Friendship').deleteMany({});
  await befriend('alice', 'bob');
  assert.equal((await call('cara', 'DELETE', '/friends/alice')).status, 404);
  assert.equal((await call('cara', 'DELETE', '/friends/bob')).status, 404);
  assert.equal((await call('alice', 'GET', '/friends/status/bob')).data.status, 'friends', 'untouched');

  await call('alice', 'POST', '/friends/requests', { receiver_id: 'cara' });
  assert.equal((await call('alice', 'DELETE', '/friends/cara')).status, 404, 'pending is not a friendship');
  assert.equal((await call('alice', 'GET', '/friends/status/cara')).data.status, 'pending_sent');
});
