// backend/scripts/init_db.js
const { connectDb, closePool, testConnection, getCollection } = require('../src/config/db');

const REQUIRED_TABLES = [
  'User',
  'Post',
  'Comment',
  'Reaction',
  'Friendship',
  'Notification',
];

const REQUIRED_INDEXES = [
  'idx_post_author_created',
  'idx_comment_post_created',
  'idx_reaction_user',
  'idx_friendship_receiver_status',
  'idx_friendship_requester_status',
  'idx_notification_recipient_unread',
  'idx_user_full_name',
  'idx_friendship_bidirectional_pair',
];

async function initDb() {
  console.log('=============================================================================');
  console.log('Facebook Clone (fb_clone) - MongoDB Database Initialization & Verification');
  console.log('=============================================================================');

  try {
    // 1. Connection Pre-flight Check
    console.log('[1/4] Checking MongoDB connectivity...');
    const connInfo = await testConnection();
    console.log(`      ✓ Connected to database: "${connInfo.database}"`);
    console.log(`      ✓ MongoDB Engine: ${connInfo.version}`);
    console.log(`      ✓ Server Time: ${connInfo.time.toISOString()}`);

    const db = await connectDb();

    // 2. Drop / Clean existing collections
    console.log('[2/4] Initializing collections & indexes in MongoDB...');
    const existingColls = (await db.listCollections().toArray()).map((c) => c.name);

    for (const collName of REQUIRED_TABLES) {
      if (existingColls.includes(collName)) {
        await db.collection(collName).deleteMany({});
      } else {
        await db.createCollection(collName);
      }
    }

    // Create Indexes
    // User indexes
    const userColl = getCollection('User');
    await userColl.createIndex(
      { email: 1 },
      {
        unique: true,
        partialFilterExpression: { email: { $type: 'string' } },
        name: 'idx_user_email',
      }
    );
    await userColl.createIndex(
      { phone: 1 },
      {
        unique: true,
        partialFilterExpression: { phone: { $type: 'string' } },
        name: 'idx_user_phone',
      }
    );
    await userColl.createIndex({ full_name: 1 }, { name: 'idx_user_full_name' });

    // Post indexes
    const postColl = getCollection('Post');
    await postColl.createIndex(
      { author_id: 1, created_at: -1 },
      { name: 'idx_post_author_created' }
    );
    await postColl.createIndex({ shared_post_id: 1 }, { name: 'idx_post_shared_post' });

    // Comment indexes
    const commentColl = getCollection('Comment');
    await commentColl.createIndex(
      { post_id: 1, created_at: -1 },
      { name: 'idx_comment_post_created' }
    );

    // Reaction indexes
    const reactionColl = getCollection('Reaction');
    await reactionColl.createIndex(
      { post_id: 1, user_id: 1 },
      { unique: true, name: 'idx_reaction_post_user_unique' }
    );
    await reactionColl.createIndex({ user_id: 1 }, { name: 'idx_reaction_user' });

    // Friendship indexes
    const friendshipColl = getCollection('Friendship');
    await friendshipColl.createIndex(
      { pair: 1 },
      { unique: true, name: 'idx_friendship_bidirectional_pair' }
    );
    await friendshipColl.createIndex(
      { receiver_id: 1, status: 1 },
      { name: 'idx_friendship_receiver_status' }
    );
    await friendshipColl.createIndex(
      { requester_id: 1, status: 1 },
      { name: 'idx_friendship_requester_status' }
    );

    // Notification indexes
    const notificationColl = getCollection('Notification');
    await notificationColl.createIndex(
      { recipient_id: 1, is_read: 1, created_at: -1 },
      { name: 'idx_notification_recipient_unread' }
    );

    console.log('      ✓ Successfully initialized all 6 collections and indexes.');

    // 3. Verify Exactly 6 Collections Exist and Are Clean (0 Rows)
    console.log('[3/4] Verifying collections and data cleanliness...');
    for (const collName of REQUIRED_TABLES) {
      const count = await getCollection(collName).countDocuments();
      if (count !== 0) {
        throw new Error(`Cleanliness FAILED: Collection "${collName}" contains ${count} documents (expected 0).`);
      }
      console.log(`      ✓ Collection "${collName}": EXISTS, 0 documents (Clean).`);
    }

    // 4. Verify Performance and Integrity Indexes
    console.log('[4/4] Verifying performance and integrity indexes...');
    const allDetectedIndexes = [];
    for (const collName of REQUIRED_TABLES) {
      const idxs = await getCollection(collName).indexes();
      for (const i of idxs) {
        allDetectedIndexes.push(i.name);
      }
    }

    for (const indexName of REQUIRED_INDEXES) {
      if (allDetectedIndexes.includes(indexName)) {
        console.log(`      ✓ Index "${indexName}": VERIFIED.`);
      } else {
        console.warn(`      ⚠ Warning: Expected index "${indexName}" was not detected.`);
      }
    }

    console.log('=============================================================================');
    console.log('✓ SUCCESS: Clean MongoDB database initialization complete. 6 collections verified with 0 documents.');
    console.log('=============================================================================');

    await closePool();
    if (require.main === module) {
      process.exit(0);
    }
    return true;
  } catch (err) {
    console.error('\n❌ [ERROR] Database initialization failed:');
    console.error(`   Message: ${err.message}`);
    await closePool().catch(() => {});
    if (require.main === module) {
      process.exit(1);
    }
    throw err;
  }
}

if (require.main === module) {
  initDb();
}

module.exports = { initDb, REQUIRED_TABLES, REQUIRED_INDEXES };
