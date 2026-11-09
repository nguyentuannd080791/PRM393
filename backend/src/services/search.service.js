const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { PUBLIC_USER_FIELDS, pagination, relationship } = require('./friends.service');

function keyword(value) {
  if (value === undefined) return '';
  if (typeof value !== 'string' || value.length > 100) {
    throw new AppError('Search keyword must be a string of at most 100 characters.', 400);
  }
  return value.trim();
}

function literalPattern(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function search(viewer, kind, query) {
  const term = keyword(query.q);
  const { page, limit, skip } = pagination(query);
  const empty = { data: [], pagination: { page, limit, total: 0, has_more: false } };
  if (!term) return empty;
  const regex = { $regex: literalPattern(term), $options: 'i' };
  const relationships = await getCollection('Friendship').find({
    $or: [{ requester_id: viewer }, { receiver_id: viewer }],
    status: { $in: ['pending', 'accepted'] },
  }).toArray();
  let filter;
  let collection;
  if (kind === 'users') {
    collection = getCollection('User');
    filter = { id: { $ne: viewer }, full_name: regex };
  } else {
    const friendIds = relationships.filter(r => r.status === 'accepted')
      .map(r => r.requester_id === viewer ? r.receiver_id : r.requester_id);
    collection = getCollection('Post');
    filter = { $and: [
      { content: regex, is_deleted: { $ne: true }, isDeleted: { $ne: true }, deleted_at: null },
      // This module searches text posts and preserves existing audience restrictions.
      { $or: [{ media_urls: { $exists: false } }, { media_urls: { $size: 0 } }] },
      { $or: [
        { audience: { $exists: false } }, { audience: null }, { audience: 'public' },
        { author_id: viewer }, { audience: 'friends', author_id: { $in: friendIds } },
      ] },
    ] };
  }
  const projection = kind === 'users' ? PUBLIC_USER_FIELDS :
    { _id: 0, id: 1, author_id: 1, content: 1, created_at: 1 };
  const [rows, total] = await Promise.all([
    collection.find(filter, { projection }).sort(kind === 'users' ? { full_name: 1, id: 1 } : { created_at: -1, id: 1 })
      .skip(skip).limit(limit).maxTimeMS(3000).toArray(),
    collection.countDocuments(filter, { maxTimeMS: 3000 }),
  ]);
  let data;
  if (kind === 'users') {
    const byUser = new Map(relationships.map(row => [
      row.requester_id === viewer ? row.receiver_id : row.requester_id, row,
    ]));
    data = rows.map(user => ({ ...user, relationship: relationship(byUser.get(user.id), viewer) }));
  } else {
    const users = await getCollection('User').find({ id: { $in: rows.map(row => row.author_id) } },
      { projection: PUBLIC_USER_FIELDS }).toArray();
    const byId = new Map(users.map(user => [user.id, user]));
    data = rows.map(post => ({ ...post, author: byId.get(post.author_id) || { id: post.author_id, full_name: 'Deleted user' } }));
  }
  return { data, pagination: { page, limit, total, has_more: skip + limit < total } };
}

module.exports = { search, keyword, literalPattern };
