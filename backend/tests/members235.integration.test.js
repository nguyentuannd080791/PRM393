// Member 2 (posts), Member 3 (interactions), Member 5 (profile) API checks.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

// Dedicated local database: never touches the shared team database.
const testDbName = `prm393_members235_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'members235-isolated-integration-tests';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const app = require('../src/app');
let server;
let base;

const token = id => jwt.sign({ userId: id }, process.env.JWT_SECRET);
async function api(user, method, path, body) {
  const headers = user ? { Authorization: `Bearer ${token(user)}` } : {};
  if (body) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${base}${path}`, { method, headers, body: body && JSON.stringify(body) });
  return { status: response.status, ...await response.json() };
}

before(async () => {
  await db.connectDb();
  await db.getCollection('User').insertMany(['alice', 'bob', 'cara'].map(id =>
    ({ _id: id, id, full_name: id.toUpperCase(), password_hash: 'private', created_at: new Date() })));
  await db.getCollection('Friendship').insertOne({
    id: 'f1', pair: 'alice:bob', requester_id: 'alice', receiver_id: 'bob', status: 'accepted',
  });
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});

after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName && testDbName.startsWith('prm393_members235_test_')) {
    await db.getDb().dropDatabase();
  }
  await db.closePool();
});

test('Member 2: create, edit, delete own posts; insights are author-only', async () => {
  assert.equal((await api('bob', 'POST', '/posts', { content: '   ' })).status, 400);
  const created = await api('bob', 'POST', '/posts', { content: 'hello', audience: 'public' });
  assert.equal(created.status, 201);
  const id = created.data.id;

  assert.equal((await api('alice', 'PUT', `/posts/${id}`, { content: 'hacked' })).status, 403);
  const edited = await api('bob', 'PUT', `/posts/${id}`, { content: 'hello world', audience: 'friends' });
  assert.equal(edited.data.content, 'hello world');
  assert.equal((await api('cara', 'GET', `/feed/posts/${id}`)).status, 404, 'friends-only hidden from cara');

  await api('alice', 'PUT', `/feed/posts/${id}/like`);
  const insights = await api('bob', 'GET', `/posts/${id}/insights`);
  assert.equal(insights.data.likes, 1);
  assert.equal((await api('alice', 'GET', `/posts/${id}/insights`)).status, 403);

  assert.equal((await api('alice', 'DELETE', `/posts/${id}`)).status, 403);
  assert.equal((await api('bob', 'DELETE', `/posts/${id}`)).status, 200);
  assert.equal((await api('bob', 'GET', `/feed/posts/${id}`)).status, 404);
});

test('Member 3: comments, liked and saved lists', async () => {
  const id = (await api('bob', 'POST', '/posts', { content: 'discuss' })).data.id;
  assert.equal((await api(null, 'GET', `/posts/${id}/comments`)).status, 401);
  assert.equal((await api('alice', 'POST', `/posts/${id}/comments`, { content: ' ' })).status, 400);

  const added = await api('alice', 'POST', `/posts/${id}/comments`, { content: 'nice' });
  assert.equal(added.status, 201);
  const list = await api('bob', 'GET', `/posts/${id}/comments`);
  assert.deepEqual(list.data.map(c => [c.content, c.author.full_name, c.is_mine]), [['nice', 'ALICE', false]]);
  assert.equal((await api('bob', 'GET', `/feed/posts/${id}`)).data.comment_count, 1);
  const notes = await api('bob', 'GET', '/notifications');
  assert.ok(notes.data.some(n => n.type === 'comment' && n.post_id === id));

  // BR02: only the author can delete a comment.
  assert.equal((await api('bob', 'DELETE', `/comments/${added.data.id}`)).status, 403);
  assert.equal((await api('alice', 'DELETE', `/comments/${added.data.id}`)).status, 200);
  assert.equal((await api('bob', 'GET', `/posts/${id}/comments`)).data.length, 0);

  await api('alice', 'PUT', `/feed/posts/${id}/like`);
  await api('alice', 'PUT', `/feed/posts/${id}/save`);
  await api('alice', 'PUT', `/feed/posts/${id}/save`); // BR03: still saved once
  assert.deepEqual((await api('alice', 'GET', '/me/liked-posts')).data.map(p => p.id), [id]);
  const saved = await api('alice', 'GET', '/me/saved-posts');
  assert.deepEqual(saved.data.map(p => [p.id, p.saved_by_me]), [[id, true]]);
  assert.equal(saved.pagination.total, 1);
  await api('alice', 'DELETE', `/feed/posts/${id}/save`);
  assert.equal((await api('alice', 'GET', '/me/saved-posts')).data.length, 0);
  assert.equal((await api('cara', 'GET', '/me/liked-posts')).data.length, 0);
});

test('Member 5: view and edit profile', async () => {
  const me = await api('alice', 'GET', '/users/alice');
  assert.equal(me.data.relationship_status, 'self');
  assert.equal((await api('alice', 'GET', '/users/me')).data.user.id, 'alice');
  assert.equal(me.data.friends_count, 1);
  assert.equal(me.data.user.password_hash, undefined);
  assert.equal((await api('alice', 'GET', '/users/bob')).data.relationship_status, 'friends');
  assert.equal((await api('cara', 'GET', '/users/bob')).data.mutual_friends_count, 0);

  assert.equal((await api('alice', 'PUT', '/users/profile', { full_name: '  ' })).status, 400);
  const updated = await api('alice', 'PUT', '/users/profile', { full_name: 'Alice A', bio: 'hi' });
  assert.equal(updated.data.user.full_name, 'Alice A');
  assert.equal((await api('bob', 'GET', '/users/alice')).data.user.bio, 'hi');

  await api('bob', 'POST', '/posts', { content: 'for friends', audience: 'friends' });
  const forAlice = await api('alice', 'GET', '/users/bob/posts');
  assert.ok(forAlice.data.some(p => p.content === 'for friends' && 'reaction_count' in p));
  assert.equal(forAlice.pagination.totalPages, 1);
  assert.ok(!(await api('cara', 'GET', '/users/bob/posts')).data.some(p => p.content === 'for friends'));
});

test('UC01/UC02: register with name + phone + password, then log in by phone', async () => {
  const reg = body => api(null, 'POST', '/auth/register', body);
  assert.equal((await reg({ full_name: 'Dan', password: 'abcd1234' })).status, 400, 'phone required');
  const ok = await reg({ full_name: 'Dan', phone: '0912345678', password: 'abcd1234' });
  assert.equal(ok.status, 201);
  assert.equal(ok.data.user.password_hash, undefined);
  assert.equal((await reg({ full_name: 'Dan2', phone: '0912345678', password: 'abcd1234' })).status, 409, 'BR01 unique');
  const login = await api(null, 'POST', '/auth/login', { phone: '0912345678', password: 'abcd1234' });
  assert.equal(login.status, 200);
  assert.equal((await api(null, 'POST', '/auth/login', { phone: '0912345678', password: 'wrong999' })).status, 401);
  assert.equal((await api(null, 'GET', '/auth/me')).status, 401);
  assert.equal((await api(login.data.user.id, 'GET', '/auth/me')).status, 200);
});
