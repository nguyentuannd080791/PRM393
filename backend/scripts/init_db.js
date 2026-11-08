const fs = require('fs');
const path = require('path');
const { closePool, testConnection, query } = require('../src/config/db');

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
  console.log('Facebook Clone (fb_clone) - Database Schema Migration & Verification');
  console.log('=============================================================================');

  try {
    // 1. Connection Pre-flight Check
    console.log('[1/4] Checking PostgreSQL connectivity...');
    const connInfo = await testConnection();
    console.log(`      ✓ Connected to database: "${connInfo.database}"`);
    console.log(`      ✓ PostgreSQL Engine: ${connInfo.version.split(',')[0]}`);
    console.log(`      ✓ Server Time: ${connInfo.time.toISOString()}`);

    // 2. Read and Execute schema.sql
    console.log('[2/4] Executing schema.sql DDL...');
    const schemaPath = path.resolve(__dirname, '../src/config/schema.sql');
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found at: ${schemaPath}`);
    }
    const ddl = fs.readFileSync(schemaPath, 'utf8');
    await query(ddl);
    console.log('      ✓ Successfully executed DDL statements.');

    // 3. Verify Exactly 6 Tables Exist and Are Clean (0 Rows)
    console.log('[3/4] Verifying tables and data cleanliness...');
    const tablesResult = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);

    const existingTables = tablesResult.rows.map(r => r.table_name);
    console.log(`      Found ${existingTables.length} tables in 'public' schema: ${existingTables.join(', ')}`);

    for (const tableName of REQUIRED_TABLES) {
      if (!existingTables.includes(tableName)) {
        throw new Error(`Verification FAILED: Table "${tableName}" was NOT found in the database.`);
      }

      // Check row count is strictly 0
      const countResult = await query(`SELECT COUNT(*)::int AS count FROM "${tableName}"`);
      const rowCount = countResult.rows[0].count;
      if (rowCount !== 0) {
        throw new Error(`Cleanliness FAILED: Table "${tableName}" contains ${rowCount} rows (expected 0).`);
      }
      console.log(`      ✓ Table "${tableName}": EXISTS, 0 rows (Clean).`);
    }

    // 4. Verify Performance and Unique Indexes Exist
    console.log('[4/4] Verifying performance and integrity indexes...');
    const indexesResult = await query(`
      SELECT indexname 
      FROM pg_indexes 
      WHERE schemaname = 'public';
    `);
    const existingIndexes = indexesResult.rows.map(r => r.indexname);

    for (const indexName of REQUIRED_INDEXES) {
      if (existingIndexes.includes(indexName)) {
        console.log(`      ✓ Index "${indexName}": VERIFIED.`);
      } else {
        console.warn(`      ⚠ Warning: Expected index "${indexName}" was not detected in pg_indexes.`);
      }
    }

    console.log('=============================================================================');
    console.log('✓ SUCCESS: Clean database initialization complete. 6 tables verified with 0 rows.');
    console.log('=============================================================================');
    await closePool();
    if (require.main === module) {
      process.exit(0);
    }
    return true;
  } catch (err) {
    console.error('\n❌ [ERROR] Database initialization failed:');
    console.error(`   Message: ${err.message}`);
    if (err.code === 'ECONNREFUSED') {
      console.error('\n   Diagnostic: Cannot connect to PostgreSQL server.');
      console.error('   Please ensure:');
      console.error('   1. PostgreSQL server is running locally (port 5432) OR Docker container is active.');
      console.error('   2. OR configure a valid cloud DATABASE_URL in backend/.env.');
    } else if (err.code === '3D000') {
      console.error('\n   Diagnostic: Target database does not exist.');
      console.error('   Create the database first: CREATE DATABASE fb_clone;');
    }
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
