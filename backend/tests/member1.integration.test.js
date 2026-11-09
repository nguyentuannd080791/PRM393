const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

// Dedicated local database: never touches the shared team database.
const testDbName = `prm393_member1_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'member1-isolated-integration-tests';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const app = require('../src/app');
const { ensureMember1Indexes } = require('../src/config/member1_indexes');
let server;
let base;

const token = id => jwt.sign({ userId: id }, process.env.JWT_SECRET);
async function api(user, method, path) {
  const response = await fetch(`${base}${path}`, {
    method, headers: user ? { Authorization: `Bearer ${token(user)}` } : {},
  });
  return { status: response.status, ...await response.json() };
}

before(async () => {
  await db.connectDb();
  await ensureMember1Indexes();
  await db.getCollection('User').insertMany(['alice', 'bob', 'cara'].map(id =>
    ({ _id: id, id, full_name: id.toUpperCase(), password_hash: 'private' })));
  const now = Date.now();
  const post = (id, author, extra, age) => ({
    id, author_id: author, content: `post ${id}`, created_at: new Date(now - age * 1000), ...extra,
  });
  await db.getCollection('Post').insertMany([
    post('pub', 'bob', { audience: 'public' }, 1),
    post('old', 'bob', {}, 2),
    post('friends', 'bob', { audience: 'friends' }, 3),
    post('private', 'bob', { audience: 'only_me' }, 4),
    post('gone', 'bob', { audience: 'public', is_deleted: true }, 5),
    post('mine', 'alice', { audience: 'only_me' }, 6),
  ]);
  await db.getCollection('Friendship').insertOne({
    id: 'f1', pair: 'alice:bob', requester_id: 'alice', receiver_id: 'bob', status: 'accepted',
  });
  await db.getCollection('Comment').insertOne({ id: 'c1', post_id: 'pub', author_id: 'bob', content: 'hi', created_at: new Date() });
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});

after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName && testDbName.startsWith('prm393_member1_test_')) {
    await db.getDb().dropDatabase();
  }
  await db.closePool();
});

test('feed and post detail respect audience, deletion and pagination', async () => {
  assert.equal((await api(null, 'GET', '/feed')).status, 401);
  const alice = await api('alice', 'GET', '/feed');
  assert.deepEqual(alice.data.map(p => p.id), ['pub', 'old', 'friends', 'mine']);
  assert.equal(alice.data[0].comment_count, 1);
  assert.equal(alice.data[0].author.full_name, 'BOB');
  // Cara is not Bob's friend: no friends-only, private, deleted or other people's only_me posts.
  assert.deepEqual((await api('cara', 'GET', '/feed')).data.map(p => p.id), ['pub', 'old']);
  const paged = await api('alice', 'GET', '/feed?limit=3&page=2');
  assert.deepEqual(paged.data.map(p => p.id), ['mine']);
  assert.equal(paged.pagination.has_more, false);
  assert.equal((await api('alice', 'GET', '/feed?limit=500')).status, 400);

  assert.equal((await api('alice', 'GET', '/feed/posts/friends')).status, 200);
  for (const id of ['friends', 'private', 'gone', 'missing']) {
    assert.equal((await api('cara', 'GET', `/feed/posts/${id}`)).status, 404, id);
  }
});

test('like and save are idempotent and create one notification', async () => {
  let r = await api('alice', 'PUT', '/feed/posts/pub/like');
  assert.equal(r.data.like_count, 1);
  assert.equal(r.data.liked_by_me, true);
  r = await api('alice', 'PUT', '/feed/posts/pub/like');
  assert.equal(r.data.like_count, 1);
  assert.equal((await api('bob', 'GET', '/notifications')).data.length, 1);

  const likes = await api('bob', 'GET', '/feed/posts/pub/likes');
  assert.deepEqual(likes.data.map(u => u.id), ['alice']);
  assert.equal(likes.data[0].password_hash, undefined);

  r = await api('alice', 'PUT', '/feed/posts/pub/save');
  assert.equal(r.data.saved_by_me, true);
  r = await api('alice', 'DELETE', '/feed/posts/pub/save');
  assert.equal(r.data.saved_by_me, false);
  r = await api('alice', 'DELETE', '/feed/posts/pub/like');
  assert.equal(r.data.like_count, 0);
  assert.equal((await api('cara', 'PUT', '/feed/posts/private/like')).status, 404);
});

test('notifications are private to the recipient and can be marked read', async () => {
  const bob = await api('bob', 'GET', '/notifications');
  assert.equal(bob.unread_count, 1);
  assert.equal(bob.data[0].type, 'reaction');
  assert.equal(bob.data[0].actor.full_name, 'ALICE');
  assert.equal(bob.data[0].post_id, 'pub');
  const id = bob.data[0].id;

  assert.equal((await api('alice', 'GET', '/notifications')).data.length, 0);
  assert.equal((await api('alice', 'PATCH', `/notifications/${id}/read`)).status, 404);
  assert.equal((await api('bob', 'GET', '/notifications')).unread_count, 1);

  assert.equal((await api('bob', 'PATCH', `/notifications/${id}/read`)).status, 200);
  assert.equal((await api('bob', 'GET', '/notifications')).unread_count, 0);

  await api('cara', 'PUT', '/feed/posts/pub/like');
  assert.equal((await api('bob', 'GET', '/notifications')).unread_count, 1);
  assert.equal((await api('bob', 'PATCH', '/notifications/read-all')).data.updated, 1);
  assert.equal((await api('bob', 'GET', '/notifications')).unread_count, 0);
});
