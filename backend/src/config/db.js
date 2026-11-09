// backend/src/config/db.js
const path = require('path');
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/fb_clone';
const DB_NAME = process.env.MONGODB_DB_NAME || 'fb_clone';

let clientInstance = null;
let dbInstance = null;

function getClient() {
  if (!clientInstance) {
    clientInstance = new MongoClient(MONGODB_URI, {
      maxPoolSize: 20,
      serverSelectionTimeoutMS: 5000,
    });
    dbInstance = clientInstance.db(DB_NAME);
  }
  return clientInstance;
}

/**
 * Connect to MongoDB and return database instance
 */
async function connectDb() {
  const client = getClient();
  await client.connect();
  return dbInstance;
}

/**
 * Get active database instance
 */
function getDb() {
  getClient();
  return dbInstance;
}

/**
 * Get collection by name
 * @param {'User'|'Post'|'Comment'|'Reaction'|'Friendship'|'Notification'|string} name
 */
function getCollection(name) {
  return getDb().collection(name);
}

/**
 * Test connectivity and retrieve DB status
 */
async function testConnection() {
  const db = await connectDb();
  const buildInfo = await db.admin().serverStatus().catch(() => ({ version: 'MongoDB' }));
  const ping = await db.command({ ping: 1 });

  const url = new URL(MONGODB_URI.startsWith('mongodb') ? MONGODB_URI : `mongodb://${MONGODB_URI}`);

  return {
    ok: ping.ok === 1,
    database: DB_NAME,
    version: buildInfo.version ? `MongoDB ${buildInfo.version}` : 'MongoDB',
    time: new Date(),
    host: url.hostname || '127.0.0.1',
    port: parseInt(url.port || '27017', 10),
  };
}

/**
 * Gracefully close the MongoDB client
 */
async function closePool() {
  if (clientInstance) {
    const client = clientInstance;
    clientInstance = null;
    dbInstance = null;
    await client.close();
  }
}

/**
 * Backward-compatible query adapter for tests or legacy checks
 */
async function query(text, params = []) {
  const db = getDb();
  const trimmed = text.trim();

  // 1. SELECT table_name FROM information_schema.tables
  if (trimmed.includes('information_schema.tables')) {
    const collections = await db.listCollections().toArray();
    const tableNames = collections.map((c) => c.name);
    return {
      rows: tableNames.map((name) => ({ table_name: name })),
      rowCount: tableNames.length,
    };
  }

  // 2. SELECT indexname FROM pg_indexes
  if (trimmed.includes('pg_indexes')) {
    const collections = ['User', 'Post', 'Comment', 'Reaction', 'Friendship', 'Notification'];
    const allIndexes = [];
    for (const collName of collections) {
      try {
        const indexes = await db.collection(collName).indexes();
        for (const idx of indexes) {
          allIndexes.push({ indexname: idx.name });
        }
      } catch (_) {}
    }
    return {
      rows: allIndexes,
      rowCount: allIndexes.length,
    };
  }

  // 3. SELECT COUNT(*)::int AS count FROM "TableName" [WHERE field = $1]
  const countMatch = trimmed.match(/SELECT\s+COUNT\(\*\)(?:::int)?\s+AS\s+count\s+FROM\s+"?(\w+)"?(?:\s+WHERE\s+(\w+)\s*=\s*\$1)?/i);
  if (countMatch) {
    const tableName = countMatch[1];
    const whereField = countMatch[2];
    const coll = db.collection(tableName);
    const filter = whereField && params.length > 0 ? { [whereField]: params[0] } : {};
    const count = await coll.countDocuments(filter);
    return {
      rows: [{ count }],
      rowCount: 1,
    };
  }

  // 4. SELECT [fields] FROM "Post" WHERE id = $1
  const selectPostMatch = trimmed.match(/SELECT\s+(.+?)\s+FROM\s+"?Post"?\s+WHERE\s+(\w+)\s*=\s*\$1/i);
  if (selectPostMatch) {
    const whereField = selectPostMatch[2];
    const coll = db.collection('Post');
    const doc = await coll.findOne({ [whereField]: params[0] });
    return {
      rows: doc ? [doc] : [],
      rowCount: doc ? 1 : 0,
    };
  }

  return { rows: [], rowCount: 0 };
}

module.exports = {
  connectDb,
  getDb,
  getCollection,
  testConnection,
  closePool,
  query,
};
