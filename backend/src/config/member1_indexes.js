const { getCollection } = require('./database');

// Non-destructive, like member4_indexes.
async function ensureMember1Indexes() {
  await Promise.all([
    getCollection('Reaction').createIndex({ post_id: 1, user_id: 1 }, { unique: true, name: 'idx_reaction_post_user_unique' }),
    getCollection('Comment').createIndex({ post_id: 1, created_at: -1 }, { name: 'idx_comment_post_created' }),
    getCollection('SavedPost').createIndex({ post_id: 1, user_id: 1 }, { unique: true, name: 'idx_saved_post_user_unique' }),
    getCollection('Notification').createIndex({ recipient_id: 1, is_read: 1, created_at: -1 }, { name: 'idx_notification_recipient_unread' }),
    getCollection('Notification').createIndex({ id: 1 }, { name: 'idx_notification_id' }),
  ]);
}

module.exports = { ensureMember1Indexes };
