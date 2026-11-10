const { getCollection } = require('./database');

// BR01: the phone number is unique. The register check alone races under concurrent requests.
async function ensureAuthIndexes() {
  const users = getCollection('User');
  try {
    await users.createIndex({ phone: 1 }, {
      unique: true, name: 'idx_user_phone_unique', partialFilterExpression: { phone: { $type: 'string' } },
    });
  } catch (error) {
    // Pre-existing duplicate phones must be fixed by hand; do not stop the whole API for it.
    console.error('[DB] Could not create unique phone index:', error.message);
  }
}

module.exports = { ensureAuthIndexes };
