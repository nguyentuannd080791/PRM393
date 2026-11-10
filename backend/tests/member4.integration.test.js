const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

// Dedicated local database: never reset or initialize the shared team database.
const testDbName = `prm393_member4_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'member4-isolated-integration-tests';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
const app = require('../src/app');
const { ensureMember4Indexes } = require('../src/config/member4_indexes');
let server;
let base;

const token = id => jwt.sign({ userId: id }, process.env.JWT_SECRET);
async function api(user, method, path, body) {
  const response = await fetch(`${base}${path}`, {
    method, headers: { 'Content-Type': 'application/json', ...(user ? { Authorization: `Bearer ${token(user)}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, ...await response.json() };
}
const send = (a, b) => api(a, 'POST', '/friends/requests', { receiver_id: b, requester_id: 'forged-user' });
const change = (user, id, action) => api(user, 'PATCH', `/friends/requests/${id}/${action}`);

before(async () => {
  await db.connectDb();
  await ensureMember4Indexes();
  await db.getCollection('User').insertMany([
    { _id: 'alice', id: 'alice', full_name: 'Minh Alice', password_hash: 'private', email: 'private@example.com', phone: 'private' },
    { _id: 'bob', id: 'bob', full_name: 'Minh Bob', password_hash: 'private', bio: 'Hello there' },
    { _id: 'cara', id: 'cara', full_name: 'Cara Nguyen', password_hash: 'private' },
    { _id: 'dan', id: 'dan', full_name: 'Dan Le', password_hash: 'private' },
    { _id: 'literal', id: 'literal', full_name: 'Literal .* Person', password_hash: 'private' },
  ]);
  const date = new Date();
  await db.getCollection('Post').insertMany([
    { id: 'public', author_id: 'bob', content: 'Learning Flutter today', created_at: date, audience: 'public' },
    { id: 'deleted', author_id: 'bob', content: 'Flutter deleted', created_at: date, is_deleted: true },
    { id: 'deletedCamel', author_id: 'bob', content: 'Flutter deleted', created_at: date, isDeleted: true },
    { id: 'private', author_id: 'bob', content: 'Flutter private', created_at: date, audience: 'only_me' },
    { id: 'friends', author_id: 'bob', content: 'Flutter friends', created_at: date, audience: 'friends' },
    { id: 'media', author_id: 'bob', content: 'Flutter picture', created_at: date, media_urls: ['image'] },
    { id: 'own', author_id: 'alice', content: 'Flutter notes', created_at: date, audience: 'only_me' },
  ]);
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});

after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName && testDbName.startsWith('prm393_member4_test_')) {
    await db.getDb().dropDatabase();
  }
  await db.closePool();
});

test('Member 4 real MongoDB API workflows', async t => {
  await t.test('protected APIs reject absent tokens and deleted identities', async () => {
    for (const path of ['/search/users?q=minh', '/search/posts?q=flutter', '/friends', '/friends/requests/received']) {
      assert.equal((await api(null, 'GET', path)).status, 401);
    }
    assert.equal((await api('missing-user', 'GET', '/friends')).status, 404);
  });

  await t.test('partial case-insensitive people search excludes self and private fields', async () => {
    const result = await api('alice', 'GET', '/search/users?q=MINH');
    assert.equal(result.status, 200);
    assert.deepEqual(result.data.map(row => row.id), ['bob']);
    assert.equal(result.data[0].relationship.status, 'none');
    for (const field of ['password_hash', 'email', 'phone', '_id']) assert.equal(result.data[0][field], undefined);
    assert.equal((await api('alice', 'GET', '/search/users?q=')).data.length, 0);
  });

  await t.test('regex metacharacters are literal and invalid query/pagination are rejected', async () => {
    const result = await api('alice', 'GET', '/search/users?q=.*');
    assert.deepEqual(result.data.map(row => row.id), ['literal']);
    assert.equal((await api('alice', 'GET', '/search/users?q[$ne]=x')).status, 400);
    assert.equal((await api('alice', 'GET', '/search/users?q=x&limit=101')).status, 400);
    assert.equal((await api('alice', 'GET', '/friends?page=0')).status, 400);
    assert.equal((await api('alice', 'GET', '/search/users?q=' + 'a'.repeat(101))).status, 400);
  });

  await t.test('post search excludes deleted, media and private posts while allowing own posts', async () => {
    const result = await api('alice', 'GET', '/search/posts?q=FLUTTER');
    assert.equal(result.status, 200);
    assert.deepEqual(result.data.map(post => post.id).sort(), ['own', 'public']);
    assert.equal(result.data.find(post => post.id === 'public').author.full_name, 'Minh Bob');
    assert.equal(result.data[0].author.password_hash, undefined);
  });

  await t.test('post lists apply audience visibility and return live engagement counts', async () => {
    await db.getCollection('Reaction').insertOne({
      _id: 'own-like', id: 'own-like', post_id: 'own', user_id: 'bob', type: 'like',
    });
    await db.getCollection('Comment').insertOne({
      _id: 'own-comment', id: 'own-comment', post_id: 'own', user_id: 'bob',
      content: 'Nice post', created_at: new Date(),
    });
    const ownPosts = await api('alice', 'GET', '/posts/users/alice');
    assert.equal(ownPosts.status, 200);
    assert.deepEqual(ownPosts.data.map(post => post.id), ['own']);
    assert.equal(ownPosts.data[0].likes, 1);
    assert.equal(ownPosts.data[0].comments, 1);
    const bobPosts = await api('cara', 'GET', '/posts/users/bob');
    assert.equal(bobPosts.status, 200);
    assert.deepEqual(bobPosts.data.map(post => post.id), ['media', 'public']);
    assert.equal((await api('alice', 'GET', '/posts/users/missing')).status, 404);
  });

  await t.test('post CRUD and insights are authenticated and owner-only', async () => {
    const created = await api('alice', 'POST', '/posts', {
      content: 'New post from My Posts', audience: 'public',
    });
    assert.equal(created.status, 201);
    const createdId = created.data.id;
    assert.equal(created.data.content, 'New post from My Posts');
    assert.equal((await api('bob', 'PUT', `/posts/${createdId}`, { content: 'forged' })).status, 403);
    assert.equal((await api('alice', 'PUT', `/posts/${createdId}`, { content: 'Updated from My Posts' })).data.content, 'Updated from My Posts');
    assert.equal((await api('bob', 'GET', `/posts/${createdId}/insights`)).status, 403);
    await db.getCollection('Reaction').insertOne({
      _id: `${createdId}-reaction`, id: `${createdId}-reaction`,
      post_id: createdId, user_id: 'bob', type: 'like', created_at: new Date(),
    });
    await db.getCollection('Comment').insertOne({
      _id: `${createdId}-comment`, id: `${createdId}-comment`,
      post_id: createdId, author_id: 'cara', content: 'Looks good!',
      created_at: new Date(),
    });
    const insights = await api('alice', 'GET', `/posts/${createdId}/insights`);
    assert.equal(insights.data.post_id, createdId);
    assert.equal(insights.data.content, 'Updated from My Posts');
    assert.equal(insights.data.author.full_name, 'Minh Alice');
    assert.equal(insights.data.likes, 1);
    assert.equal(insights.data.comments, 1);
    assert.equal(insights.data.engagement, 2);
    assert.deepEqual(
      insights.data.recent_activity.map(activity => [activity.actor_name, activity.action]).sort(),
      [['Cara Nguyen', 'commented'], ['Minh Bob', 'liked']],
    );
    assert.equal((await api('bob', 'DELETE', `/posts/${createdId}`)).status, 403);
    assert.equal((await api('alice', 'DELETE', `/posts/${createdId}`)).status, 200);
    assert.equal((await api('alice', 'GET', '/posts/users/alice')).data.some(post => post.id === createdId), false);
    assert.equal((await api('alice', 'POST', '/posts', { content: '   ' })).status, 400);
  });

  let ab;
  await t.test('send saves a real request, derives sender from JWT, rejects self/invalid/missing users', async () => {
    assert.equal((await send('alice', 'alice')).status, 400);
    assert.equal((await send('alice', { $ne: null })).status, 400);
    assert.equal((await send('alice', 'missing')).status, 404);
    const result = await send('alice', 'bob');
    assert.equal(result.status, 201);
    ab = result.data.id;
    assert.equal(result.data.requester_id, 'alice');
    assert.equal((await db.getCollection('Friendship').findOne({ id: ab })).status, 'pending');
    assert.equal(await db.getCollection('Notification').countDocuments({ recipient_id: 'bob', type: 'friend_request' }), 1);
  });

  await t.test('duplicates and reciprocal pending requests conflict; received/sent ownership is correct', async () => {
    assert.equal((await send('alice', 'bob')).status, 409);
    assert.equal((await send('bob', 'alice')).status, 409);
    assert.equal((await api('alice', 'GET', '/friends/requests/sent')).data[0].user.id, 'bob');
    assert.equal((await api('bob', 'GET', '/friends/requests/received')).data[0].user.id, 'alice');
    assert.equal((await api('cara', 'GET', '/friends/requests/received')).data.length, 0);
    assert.equal((await api('alice', 'GET', '/search/users?q=bob')).data[0].relationship.status, 'pending_sent');
    assert.equal((await api('bob', 'GET', '/search/users?q=alice')).data[0].relationship.status, 'pending_received');
  });

  await t.test('only recipient may accept/decline and only sender may cancel', async () => {
    for (const action of ['accept', 'decline', 'cancel']) assert.equal((await change('cara', ab, action)).status, 403);
    assert.equal((await change('alice', ab, 'accept')).status, 403);
    assert.equal((await change('alice', ab, 'decline')).status, 403);
    assert.equal((await change('bob', ab, 'cancel')).status, 403);
    assert.equal((await change('bob', 'missing', 'accept')).status, 404);
  });

  await t.test('accept is atomic, produces one mutual friendship and updates search/visibility', async () => {
    const responses = await Promise.all([change('bob', ab, 'accept'), change('bob', ab, 'decline')]);
    assert.deepEqual(responses.map(r => r.status).sort(), [200, 409]);
    // Both actions race legitimately; ensure accepted state for the remaining checks.
    const doc = await db.getCollection('Friendship').findOne({ id: ab });
    if (doc.status === 'rejected') {
      const retry = await send('alice', 'bob'); ab = retry.data.id;
      assert.equal((await change('bob', ab, 'accept')).status, 200);
    }
    assert.equal((await api('alice', 'GET', '/friends')).data[0].user.id, 'bob');
    assert.equal((await api('bob', 'GET', '/friends')).data[0].user.id, 'alice');
    assert.equal((await api('bob', 'GET', '/friends/requests/received')).data.length, 0);
    assert.equal((await api('alice', 'GET', '/friends/requests/sent')).data.length, 0);
    assert.equal((await api('alice', 'GET', '/search/users?q=bob')).data[0].relationship.status, 'friends');
    assert.equal((await api('alice', 'GET', '/friends/status/bob')).data.status, 'friends');
    assert.equal((await api('alice', 'GET', '/friends/status/alice')).data.status, 'self');
    assert.equal((await send('bob', 'alice')).status, 409);
    assert.equal((await change('bob', ab, 'accept')).status, 409);
    assert.equal(await db.getCollection('Friendship').countDocuments({ status: 'accepted' }), 1);
    assert.equal(await db.getCollection('Notification').countDocuments({ recipient_id: 'alice', type: 'friend_accept' }), 1);
    const posts = await api('alice', 'GET', '/search/posts?q=flutter');
    assert.ok(posts.data.some(post => post.id === 'friends'));
  });

  await t.test('decline and resend preserve pair uniqueness with a fresh request ID', async () => {
    const request = await send('alice', 'cara');
    assert.equal((await change('cara', request.data.id, 'decline')).data.status, 'rejected');
    assert.equal((await api('cara', 'GET', '/friends/requests/received')).data.length, 0);
    const retry = await send('cara', 'alice');
    assert.equal(retry.status, 201);
    assert.notEqual(retry.data.id, request.data.id);
    assert.equal((await change('cara', request.data.id, 'accept')).status, 404);
    assert.equal((await change('cara', retry.data.id, 'cancel')).status, 200);
    assert.equal((await api('alice', 'GET', '/search/users?q=cara')).data[0].relationship.status, 'none');
    assert.equal((await api('cara', 'GET', '/friends/requests/sent')).data.length, 0);
  });

  await t.test('simultaneous reciprocal sends create exactly one pending relationship', async () => {
    const result = await Promise.all([send('cara', 'dan'), send('dan', 'cara')]);
    assert.deepEqual(result.map(r => r.status).sort(), [201, 409]);
    assert.equal(await db.getCollection('Friendship').countDocuments({
      $or: [{ requester_id: 'cara', receiver_id: 'dan' }, { requester_id: 'dan', receiver_id: 'cara' }],
    }), 1);
  });

  await t.test('search pagination returns bounded, stable pages', async () => {
    const first = await api('alice', 'GET', '/search/users?q=i&limit=1&page=1');
    const second = await api('alice', 'GET', '/search/users?q=i&limit=1&page=2');
    assert.equal(first.data.length, 1);
    assert.equal(first.pagination.has_more, true);
    assert.notEqual(first.data[0].id, second.data[0].id);
  });
});
