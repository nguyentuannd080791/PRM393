const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

let embeddedInstance = null;

async function ensureLocalServerRunning() {
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '5432', 10);

  // If using external URL or non-localhost, do not start embedded
  if (process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost') && !process.env.DATABASE_URL.includes('127.0.0.1')) {
    return;
  }
  if (host !== 'localhost' && host !== '127.0.0.1') {
    return;
  }

  // Probe port
  const net = require('net');
  const isOpen = await new Promise((resolve) => {
    const socket = net.createConnection({ port, host: '127.0.0.1' }, () => {
      socket.end();
      resolve(true);
    });
    socket.on('error', () => {
      resolve(false);
    });
  });

  if (!isOpen) {
    try {
      const EmbeddedPostgres = require('embedded-postgres').default || require('embedded-postgres');
      const dbDir = path.resolve(__dirname, '../../.pgdata');
      const dataExists = fs.existsSync(dbDir) && fs.readdirSync(dbDir).length > 0;

      embeddedInstance = new EmbeddedPostgres({
        port,
        databaseDir: dbDir,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
      });

      if (!dataExists) {
        try {
          await embeddedInstance.initialise();
        } catch (_) {}
      }

      await embeddedInstance.start();

      try {
        await embeddedInstance.createDatabase(process.env.DB_NAME || 'fb_clone');
      } catch (_) {}

      console.log(`[DB] Native PostgreSQL 18 service active on port ${port}`);
    } catch (embErr) {
      console.warn('[DB] Could not start embedded PostgreSQL:', embErr.message);
    }
  }
}

function buildPoolConfig() {
  const isSslRequired =
    process.env.DB_SSL === 'true' ||
    (process.env.DATABASE_URL && process.env.DATABASE_URL.includes('sslmode=require'));

  const sslOption = isSslRequired ? { rejectUnauthorized: false } : false;

  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: sslOption,
      max: parseInt(process.env.DB_POOL_MAX || '20', 10),
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    };
  }

  return {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'fb_clone',
    ssl: sslOption,
    max: parseInt(process.env.DB_POOL_MAX || '20', 10),
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  };
}

let pool = null;

function getPool() {
  if (!pool) {
    pool = new Pool(buildPoolConfig());
    pool.on('error', (err) => {
      // Ignore disconnect errors during process teardown
      if (err.code !== 'ECONNRESET' && err.message !== 'Connection terminated unexpectedly') {
        console.error('[DATABASE] Unexpected pool client error:', err.message);
      }
    });
  }
  return pool;
}

/**
 * Execute parameterized SQL query ($1, $2, ...)
 * @param {string} text - Parameterized SQL string
 * @param {Array} params - Array of parameter values
 * @returns {Promise<import('pg').QueryResult>}
 */
async function query(text, params = []) {
  await ensureLocalServerRunning();
  const activePool = getPool();
  const start = Date.now();
  try {
    const result = await activePool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === 'development' && process.env.DEBUG_SQL === 'true') {
      console.log(`[SQL] ${duration}ms | rows: ${result.rowCount} | query: ${text.replace(/\s+/g, ' ').trim()}`);
    }
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    if (process.env.DEBUG_SQL === 'true') {
      console.error(`[SQL-ERROR] ${duration}ms | error: ${error.message} | query: ${text.replace(/\s+/g, ' ').trim()}`);
    }
    throw error;
  }
}

/**
 * Acquire a dedicated client for multi-statement transactions
 * @returns {Promise<import('pg').PoolClient>}
 */
async function getClient() {
  await ensureLocalServerRunning();
  const activePool = getPool();
  return activePool.connect();
}

/**
 * Test connectivity and retrieve DB status
 */
async function testConnection() {
  await ensureLocalServerRunning();
  const res = await query('SELECT current_database() AS db_name, version() AS pg_version, NOW() AS server_time');
  const cfg = buildPoolConfig();
  return {
    ok: true,
    database: res.rows[0].db_name,
    version: res.rows[0].pg_version,
    time: res.rows[0].server_time,
    host: cfg.host || 'localhost',
    port: cfg.port || 5432,
  };
}

/**
 * Gracefully close the connection pool and embedded instance if any
 */
async function closePool() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

module.exports = {
  get pool() {
    return getPool();
  },
  ensureLocalServerRunning,
  query,
  getClient,
  testConnection,
  closePool,
};
