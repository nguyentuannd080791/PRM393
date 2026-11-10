// Exact limits of every input field (one assertion per rule), plus the account-takeover regression.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const testDbName = `prm393_rules_test_${process.pid}_${Date.now()}`;
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017';
process.env.MONGODB_DB_NAME = testDbName;
process.env.JWT_SECRET = 'rules-isolated-integration-tests-secret-0123456789';
process.env.NODE_ENV = 'test';
const jwt = require('jsonwebtoken');
const db = require('../src/config/database');
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
const register = body => call(null, 'POST', '/auth/register', { full_name: 'Ok Name', phone: '0911111111', password: 'abcd1234', ...body });

before(async () => {
  await db.connectDb();
  await db.getCollection('User').insertMany(['alice', 'bob'].map(id =>
    ({ _id: id, id, full_name: id.toUpperCase(), password_hash: 'x', created_at: new Date() })));
  await new Promise(resolve => { server = app.listen(0, '127.0.0.1', resolve); });
  base = `http://127.0.0.1:${server.address().port}/api`;
});
after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  if (db.getDb().databaseName === testDbName) await db.getDb().dropDatabase();
  await db.closePool();
});

test('register: Full Name rules', async () => {
  for (const bad of ['', '   ', 'x'.repeat(101), 'bad\u0000name', 'tab\tname', 123, ['a']]) {
    assert.equal((await register({ full_name: bad, phone: '0900000100' })).status, 400, JSON.stringify(bad).slice(0, 30));
  }
  assert.equal((await register({ full_name: 'x'.repeat(100), phone: '0900000101' })).status, 201, '100 chars is the maximum');
  assert.equal((await register({ full_name: 'Nguyễn Văn Á 😀', phone: '0900000102' })).status, 201, 'unicode names allowed');
});

test('register: Phone rules (required, 9-15 digits, optional +, unique)', async () => {
  for (const bad of [undefined, '', '12345678', '1'.repeat(16), '09abc45678', '+', 'phone', '0911 22', '+84-', 99999999999]) {
    assert.equal((await register({ phone: bad })).status, 400, String(bad));
  }
  assert.equal((await register({ phone: '123456789' })).status, 201, '9 digits is the minimum');
  assert.equal((await register({ phone: '+841234567890' })).status, 201, 'leading + allowed');
  assert.equal((await register({ phone: '123456789' })).status, 409, 'BR01 phone unique');
  assert.equal((await register({ phone: '1'.repeat(15), full_name: 'Max' })).status, 201, '15 digits is the maximum');
});

test('register: Password rules (8-128, letter + number)', async () => {
  for (const bad of [undefined, '', 'abcdefg1'.slice(0, 7), 'abcdefgh', '12345678', 'a1'.repeat(65), 12345678]) {
    assert.equal((await register({ phone: '0922222222', password: bad })).status, 400, String(bad).slice(0, 20));
  }
  assert.equal((await register({ phone: '0922222222', password: 'abcdefg1' })).status, 201, '8 chars is the minimum');
});

test('register: optional fields are validated when present', async () => {
  assert.equal((await register({ phone: '0933333331', birthday: '2999-01-01' })).status, 400, 'future birthday');
  assert.equal((await register({ phone: '0933333332', birthday: 'not-a-date' })).status, 400);
  assert.equal((await register({ phone: '0933333333', birthday: '2000-01-01' })).status, 201);
  assert.equal((await register({ phone: '0933333334', bio: 'x'.repeat(151) })).status, 400, 'bio max 150');
  assert.equal((await register({ phone: '0933333335', city: 'x'.repeat(201) })).status, 400);
});

test('login: field rules and no user enumeration', async () => {
  await register({ phone: '0944444444', password: 'abcd1234' });
  for (const body of [{}, { phone: '0944444444' }, { password: 'abcd1234' }, { phone: '', password: '' }, { phone: '0944444444', password: 'x'.repeat(129) }]) {
    assert.equal((await call(null, 'POST', '/auth/login', body)).status, 400, JSON.stringify(body).slice(0, 40));
  }
  const unknown = await call(null, 'POST', '/auth/login', { phone: '0999999999', password: 'abcd1234' });
  const wrong = await call(null, 'POST', '/auth/login', { phone: '0944444444', password: 'wrongpass1' });
  assert.equal(unknown.status, 401);
  assert.equal(wrong.status, 401);
  assert.equal(unknown.message, wrong.message, 'same message whether or not the account exists');
  assert.equal((await call(null, 'POST', '/auth/login', { phone: '0944444444', password: 'abcd1234' })).status, 200);
});

test('there is no unauthenticated password-reset endpoint (account-takeover regression)', async () => {
  await register({ phone: '0955555555', password: 'abcd1234' });
  for (const path of ['/auth/forgot-password', '/auth/reset-password']) {
    const attack = await call(null, 'POST', path, { identifier: '0955555555', phone: '0955555555', new_password: 'hacked1234' });
    assert.equal(attack.status, 404, path);
  }
  assert.equal((await call(null, 'POST', '/auth/login', { phone: '0955555555', password: 'hacked1234' })).status, 401);
  assert.equal((await call(null, 'POST', '/auth/login', { phone: '0955555555', password: 'abcd1234' })).status, 200, 'original password still works');
});

test('change-password rules', async () => {
  const reg = await register({ phone: '0966666666', password: 'abcd1234' });
  const id = reg.data.user.id;
  const change = (c, n) => call(id, 'POST', '/auth/change-password', { current_password: c, new_password: n });
  assert.equal((await change('abcd1234', 'short1')).status, 400, 'too short');
  assert.equal((await change('abcd1234', 'allletters')).status, 400, 'no number');
  assert.equal((await change('abcd1234', 'a1'.repeat(65))).status, 400, '>128');
  assert.equal((await change('wrongpass1', 'newpass99')).status, 400, 'wrong current');
  assert.equal((await change(undefined, 'newpass99')).status, 400);
  assert.equal((await change('abcd1234', 'newpass99')).status, 200);
  assert.equal((await call(null, 'POST', '/auth/login', { phone: '0966666666', password: 'newpass99' })).status, 200);
});

test('post content: 1-5000 chars, audience enum', async () => {
  for (const bad of ['', '   ', 'x'.repeat(5001), null, 5, ['a']]) {
    assert.equal((await call('alice', 'POST', '/posts', { content: bad })).status, 400, String(bad).slice(0, 10));
  }
  assert.equal((await call('alice', 'POST', '/posts', { content: 'x'.repeat(5000) })).status, 201, '5000 is the maximum');
  for (const bad of ['everyone', '', null, 1, 'PUBLIC']) {
    assert.equal((await call('alice', 'POST', '/posts', { content: 'ok', audience: bad })).status, 400, String(bad));
  }
  for (const good of ['public', 'friends', 'only_me']) {
    assert.equal((await call('alice', 'POST', '/posts', { content: 'ok', audience: good })).status, 201, good);
  }
  const post = await call('alice', 'POST', '/posts', { content: 'edit me' });
  assert.equal((await call('alice', 'PUT', `/posts/${post.data.id}`, {})).status, 400, 'nothing to update');
  assert.equal((await call('alice', 'PUT', `/posts/${post.data.id}`, { content: ' ' })).status, 400);
});

test('comment: 1-1000 chars', async () => {
  const post = await call('bob', 'POST', '/posts', { content: 'discuss' });
  const add = content => call('alice', 'POST', `/posts/${post.data.id}/comments`, { content });
  for (const bad of ['', '   ', 'x'.repeat(1001), null, 7, {}]) assert.equal((await add(bad)).status, 400, String(bad).slice(0, 10));
  assert.equal((await add('x'.repeat(1000))).status, 201, '1000 is the maximum');
  assert.equal((await add('  trimmed  ')).data.content, 'trimmed');
});

test('profile: name 1-100 (required), bio <= 150, only own profile', async () => {
  const put = body => call('alice', 'PUT', '/users/profile', body);
  for (const bad of [{}, { full_name: '' }, { full_name: ' ' }, { full_name: 'x'.repeat(101) }, { full_name: 5 }, { full_name: 'a\u0000b' },
    { full_name: 'Ok', bio: 'x'.repeat(151) }, { full_name: 'Ok', bio: 5 }]) {
    assert.equal((await put(bad)).status, 400, JSON.stringify(bad).slice(0, 40));
  }
  assert.equal((await put({ full_name: 'x'.repeat(100), bio: 'y'.repeat(150) })).status, 200, 'maximums');
  const cleared = await put({ full_name: 'Alice', bio: '   ' });
  assert.equal(cleared.data.user.bio, null, 'blank bio is cleared');
  // The target is always the token's user; extra body fields are ignored.
  await put({ full_name: 'Alice', id: 'bob', phone: '0000000000', password_hash: 'pwned' });
  assert.equal((await db.getCollection('User').findOne({ id: 'bob' })).full_name, 'BOB');
  const alice = await db.getCollection('User').findOne({ id: 'alice' });
  assert.equal(alice.password_hash, 'x', 'password cannot be changed through profile update');
  assert.equal(alice.phone, undefined, 'phone cannot be changed through profile update');
});

test('friends / lists / pagination rules', async () => {
  assert.equal((await call('alice', 'POST', '/friends/requests', { receiver_id: 'alice' })).status, 400, 'self');
  assert.equal((await call('alice', 'POST', '/friends/requests', { receiver_id: 'nobody' })).status, 404);
  assert.equal((await call('alice', 'POST', '/friends/requests', {})).status, 400);
  assert.equal((await call('alice', 'POST', '/friends/requests', { receiver_id: 'bob' })).status, 201);
  assert.equal((await call('alice', 'POST', '/friends/requests', { receiver_id: 'bob' })).status, 409, 'duplicate');
  for (const q of ['?page=0', '?page=-1', '?page=x', '?limit=0', '?limit=101', '?limit=1.5', '?page=10001']) {
    assert.equal((await call('alice', 'GET', `/feed${q}`)).status, 400, q);
  }
  assert.equal((await call('alice', 'GET', '/feed?limit=100&page=10000')).status, 200, 'upper bounds accepted');
});

test('oversized request bodies are rejected (413), not processed', async () => {
  const response = await fetch(`${base}/auth/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phone: 'x', password: 'y'.repeat(200000) }),
  });
  assert.equal(response.status, 413);
});
