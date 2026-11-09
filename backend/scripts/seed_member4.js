const crypto = require('crypto');
const bcrypt = require('bcrypt');
const db = require('../src/config/database');
const { ensureMember4Indexes } = require('../src/config/member4_indexes');
const friends = require('../src/services/friends.service');
const { loginUser } = require('../src/services/auth.service');
const { search } = require('../src/services/search.service');

const SEED = 'member4-demo-v1';
const PASSWORD = 'Demo1234!';
const accounts = [
  ['a', 'Minh Nguyen'], ['b', 'Minh Pham'], ['c', 'Minh Le'],
  ['ha', 'Ha Pham'], ['nhi', 'Nhi Tran'], ['hoang', 'Hoang Le'],
  ['quang', 'Quang Le'], ['tien', 'Tien Nguyen'], ['kien', 'Kien Nguyen'],
].map(([key, name], index) => ({
  key, name, email: `member4.${key}@example.com`, phone: `090440000${index + 1}`,
}));

async function main() {
  await db.connectDb();
  await ensureMember4Indexes();
  const users = db.getCollection('User');
  // Check every identity before writing, so an existing real account is not reused or changed.
  for (const account of accounts) {
    const existing = await users.findOne({ $or: [{ email: account.email }, { phone: account.phone }] });
    if (existing && (existing.demo_seed !== SEED || existing.email !== account.email)) {
      throw new Error(`Account ${account.email} or its phone already exists outside this demo. Nothing was overwritten.`);
    }
    if (existing && !await bcrypt.compare(PASSWORD, existing.password_hash)) {
      throw new Error(`Demo password for ${account.email} was changed. It will not be reset.`);
    }
  }
  const hash = await bcrypt.hash(PASSWORD, 10);
  const byKey = {};
  let addedUsers = 0;
  for (const account of accounts) {
    const id = crypto.randomUUID();
    const result = await users.updateOne({ email: account.email }, { $setOnInsert: {
      _id: id, id, full_name: account.name, email: account.email, phone: account.phone,
      password_hash: hash, birthday: new Date('2003-01-15'), gender: 'Custom',
      avatar_url: null, cover_url: null, bio: 'Mini Social - Member 4 demo',
      city: 'Ha Noi', workplace: 'FPT University', created_at: new Date(), demo_seed: SEED,
    } }, { upsert: true });
    addedUsers += result.upsertedCount;
    byKey[account.key] = await users.findOne({ email: account.email });
  }

  // A: two existing friends, two received requests, two sent requests.
  // B and Kien stay unconnected to A so Add Friend can be exercised.
  const scenarios = [
    ['c', 'a', 'accepted'], ['a', 'tien', 'accepted'],
    ['ha', 'a', 'pending'], ['nhi', 'a', 'pending'],
    ['a', 'hoang', 'pending'], ['a', 'quang', 'pending'],
  ];
  let addedRelations = 0;
  for (const [sender, receiver, status] of scenarios) {
    const senderId = byKey[sender].id;
    const receiverId = byKey[receiver].id;
    const existing = await db.getCollection('Friendship').findOne({ pair: friends.pairKey(senderId, receiverId) });
    if (existing) continue; // Preserve manual Accept/Decline/Cancel when run again.
    const request = await friends.sendRequest(senderId, receiverId);
    if (status === 'accepted') await friends.changeRequest(receiverId, request.id, 'accept');
    addedRelations++;
  }

  const posts = [
    ['a', 'Hoc Flutter va Riverpod cho du an PRM393 Mini Social.', 'public', false],
    ['b', 'Flutter Search: tim kiem ban be va bai viet trong Mini Social.', 'public', false],
    ['c', 'MongoDB Community luu du lieu dung chung cho ca nhom PRM393.', 'public', false],
    ['ha', 'Hom nay minh vua hoan thanh giao dien Friend Requests bang Flutter.', 'public', false],
    ['nhi', 'Node.js REST API ket noi ung dung Android qua Wi-Fi noi bo.', 'public', false],
    ['tien', 'Mini Social: cung nhau hoc Flutter, ket ban va chia se y tuong.', 'public', false],
    ['b', 'Flutter private note - only its author should find this post.', 'only_me', false],
    ['c', 'Flutter deleted note - this must not appear in Search.', 'public', true],
  ];
  let addedPosts = 0;
  for (const [index, [author, content, audience, deleted]] of posts.entries()) {
    const createdAt = new Date(Date.now() - (index + 1) * 3600000);
    const result = await db.getCollection('Post').updateOne({ _id: `${SEED}-post-${index + 1}` }, {
      $setOnInsert: {
        id: crypto.randomUUID(), author_id: byKey[author].id, content, audience,
        media_urls: [], shared_post_id: null, is_deleted: deleted,
        created_at: createdAt, updated_at: createdAt, demo_seed: SEED,
      },
    }, { upsert: true });
    addedPosts += result.upsertedCount;
  }

  // Verify real authentication and read the same service data used by the API.
  await loginUser({ identifier: byKey.a.email, password: PASSWORD });
  await loginUser({ identifier: byKey.b.email, password: PASSWORD });
  const [accepted, received, sent, foundPosts] = await Promise.all([
    friends.listRelationships(byKey.a.id, 'friends', {}),
    friends.listRelationships(byKey.a.id, 'received', {}),
    friends.listRelationships(byKey.a.id, 'sent', {}),
    search(byKey.a.id, 'posts', { q: 'Flutter' }),
  ]);
  console.log(`Database: ${db.getDb().databaseName}`);
  console.log(`Inserted: ${addedUsers} users, ${addedRelations} relationships, ${addedPosts} posts.`);
  console.log(`Account A: ${accepted.data.length} friends, ${received.data.length} received, ${sent.data.length} sent.`);
  console.log(`Search Flutter: ${foundPosts.data.length} visible results.`);
  console.table(accounts.map(({ name, email, phone }) => ({ name, email, phone })));
  console.log(`Demo password: ${PASSWORD}`);
  console.log('Re-running adds missing demo data only; existing documents and request status changes are preserved.');
}

if (require.main === module) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; })
    .finally(() => db.closePool());
}

module.exports = { main };
