const { getCollection } = require('./database');

// Non-destructive: unlike db:init, this never clears team data.
async function ensureMember4Indexes() {
  await Promise.all([
    getCollection('User').createIndex({ full_name: 1 }, { name: 'idx_user_full_name' }),
    getCollection('Post').createIndex({ created_at: -1, id: 1 }, { name: 'idx_search_post_created' }),
    getCollection('Friendship').createIndex({ pair: 1 }, { unique: true, name: 'idx_friendship_bidirectional_pair' }),
    getCollection('Friendship').createIndex({ receiver_id: 1, status: 1 }, { name: 'idx_friendship_receiver_status' }),
    getCollection('Friendship').createIndex({ requester_id: 1, status: 1 }, { name: 'idx_friendship_requester_status' }),
  ]);
}

module.exports = { ensureMember4Indexes };
