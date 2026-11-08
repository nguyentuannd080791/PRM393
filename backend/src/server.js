// backend/src/server.js
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const app = require('./app');
const db = require('./config/db');

const PORT = parseInt(process.env.PORT || '5000', 10);
const HOST = '0.0.0.0';

let server = null;

async function startServer() {
  try {
    // 1. Verify PostgreSQL Database Connection
    console.log('[DB] Connecting to PostgreSQL...');
    const connInfo = await db.testConnection();
    console.log(`[DB] Connected to database "${connInfo.database}" on ${connInfo.host}:${connInfo.port}`);

    // 2. Start HTTP Server Listener
    server = app.listen(PORT, HOST, () => {
      console.log(`[SERVER] Facebook Clone REST API listening on http://${HOST}:${PORT}`);
      console.log(`[SERVER] Health check available at http://localhost:${PORT}/api/health`);
      console.log(`[SERVER] Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    // 3. Graceful Shutdown Handlers
    const shutdown = async (signal) => {
      console.log(`\n[SERVER] Received ${signal}. Initiating graceful shutdown...`);
      if (server) {
        server.close(async () => {
          console.log('[SERVER] HTTP server closed.');
          try {
            await db.closePool();
            console.log('[DB] PostgreSQL pool closed cleanly.');
          } catch (dbErr) {
            console.error('[DB] Error closing pool:', dbErr.message);
          }
          process.exit(0);
        });
      } else {
        process.exit(0);
      }

      setTimeout(() => {
        console.error('[SERVER] Forced shutdown due to timeout.');
        process.exit(1);
      }, 10000).unref();
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    return server;
  } catch (err) {
    console.error('[SERVER] Failed to start server:', err);
    process.exit(1);
  }
}

if (require.main === module) {
  startServer();
}

module.exports = { startServer, app };
