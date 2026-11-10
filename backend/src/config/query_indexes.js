const { getCollection } = require('./database');

// SRS NFR "indexed queries": every list screen filters/sorts on these fields.
async function ensureQueryIndexes() {
  await Promise.all([
    getCollection('Post').createIndex({ author_id: 1, created_at: -1 }, { name: 'idx_post_author_created' }), // My Posts, profile
    getCollection('Reaction').createIndex({ user_id: 1, created_at: -1 }, { name: 'idx_reaction_user_created' }), // Liked Posts
    getCollection('SavedPost').createIndex({ user_id: 1, created_at: -1 }, { name: 'idx_saved_user_created' }), // Saved Posts
  ]);
}

module.exports = { ensureQueryIndexes };
