const crypto = require('crypto');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { PUBLIC_USER_FIELDS, validateId, pagination } = require('./friends.service');

const UNAVAILABLE = 'This content is no longer available.';

async function friendIdsOf(viewer) {
  const rows = await getCollection('Friendship').find({
    status: 'accepted', $or: [{ requester_id: viewer }, { receiver_id: viewer }],
  }).toArray();
  return rows.map(r => (r.requester_id === viewer ? r.receiver_id : r.requester_id));
}

// Same audience rules as search: public/unset, own posts, friends-only for accepted friends.
function visibleFilter(viewer, friendIds) {
  return { $and: [
    { is_deleted: { $ne: true }, isDeleted: { $ne: true }, deleted_at: null },
    { $or: [
      { audience: { $exists: false } }, { audience: null }, { audience: 'public' },
      { author_id: viewer }, { audience: 'friends', author_id: { $in: friendIds } },
    ] },
  ] };
}

async function countsBy(collection, field, ids) {
  const rows = await getCollection(collection).aggregate([
    { $match: { [field]: { $in: ids } } }, { $group: { _id: `$${field}`, n: { $sum: 1 } } },
  ]).toArray();
  return new Map(rows.map(r => [r._id, r.n]));
}

async function enrich(viewer, posts) {
  const ids = posts.map(p => p.id);
  const [users, likes, comments, mine, saved] = await Promise.all([
    getCollection('User').find({ id: { $in: [...new Set(posts.map(p => p.author_id))] } },
      { projection: PUBLIC_USER_FIELDS }).toArray(),
    countsBy('Reaction', 'post_id', ids),
    countsBy('Comment', 'post_id', ids),
    getCollection('Reaction').find({ user_id: viewer, post_id: { $in: ids } }).toArray(),
    getCollection('SavedPost').find({ user_id: viewer, post_id: { $in: ids } }).toArray(),
  ]);
  const byUser = new Map(users.map(u => [u.id, u]));
  const liked = new Set(mine.map(r => r.post_id));
  const saves = new Set(saved.map(r => r.post_id));
  return posts.map(p => ({
    id: p.id, author_id: p.author_id, content: p.content || '', audience: p.audience || 'public',
    created_at: p.created_at, updated_at: p.updated_at || p.created_at,
    author: byUser.get(p.author_id) || { id: p.author_id, full_name: 'Deleted user' },
    like_count: likes.get(p.id) || 0, comment_count: comments.get(p.id) || 0,
    liked_by_me: liked.has(p.id), saved_by_me: saves.has(p.id),
  }));
}

async function feed(viewer, query) {
  const { page, limit, skip } = pagination({ limit: 20, ...query });
  const filter = visibleFilter(viewer, await friendIdsOf(viewer));
  const posts = getCollection('Post');
  const [rows, total] = await Promise.all([
    posts.find(filter).sort({ created_at: -1, id: 1 }).skip(skip).limit(limit).maxTimeMS(3000).toArray(),
    posts.countDocuments(filter, { maxTimeMS: 3000 }),
  ]);
  return { data: await enrich(viewer, rows), pagination: { page, limit, total, has_more: skip + limit < total } };
}

async function visiblePost(viewer, postId) {
  validateId(postId);
  const filter = { $and: [{ id: postId }, visibleFilter(viewer, await friendIdsOf(viewer))] };
  const post = await getCollection('Post').findOne(filter);
  if (!post) throw new AppError(UNAVAILABLE, 404);
  return post;
}

async function getPost(viewer, postId) {
  return (await enrich(viewer, [await visiblePost(viewer, postId)]))[0];
}

async function listLikes(viewer, postId, query) {
  await visiblePost(viewer, postId);
  const { page, limit, skip } = pagination(query);
  const reactions = getCollection('Reaction');
  const [rows, total] = await Promise.all([
    reactions.find({ post_id: postId }).sort({ created_at: -1, user_id: 1 }).skip(skip).limit(limit).toArray(),
    reactions.countDocuments({ post_id: postId }),
  ]);
  const users = await getCollection('User').find({ id: { $in: rows.map(r => r.user_id) } },
    { projection: PUBLIC_USER_FIELDS }).toArray();
  const byId = new Map(users.map(u => [u.id, u]));
  const data = rows.map(r => byId.get(r.user_id) || { id: r.user_id, full_name: 'Deleted user' });
  return { data, pagination: { page, limit, total, has_more: skip + limit < total } };
}

// PUT/DELETE are idempotent, so a double tap or retry cannot flip the state back.
async function setLike(viewer, postId, on) {
  const post = await visiblePost(viewer, postId);
  const reactions = getCollection('Reaction');
  if (on) {
    const result = await reactions.updateOne({ post_id: postId, user_id: viewer },
      { $setOnInsert: { post_id: postId, user_id: viewer, type: 'like', created_at: new Date() } },
      { upsert: true });
    if (result.upsertedCount && post.author_id !== viewer) {
      try {
        await getCollection('Notification').updateOne({ _id: `reaction:${postId}:${viewer}` }, { $setOnInsert: {
          id: crypto.randomUUID(), recipient_id: post.author_id, actor_id: viewer,
          post_id: postId, type: 'reaction', is_read: false, created_at: new Date(),
        } }, { upsert: true });
      } catch (error) { console.error('[Member1] Could not create notification:', error.message); }
    }
  } else {
    await reactions.deleteOne({ post_id: postId, user_id: viewer });
  }
  return getPost(viewer, postId);
}

async function setSaved(viewer, postId, on) {
  await visiblePost(viewer, postId);
  const saved = getCollection('SavedPost');
  if (on) {
    await saved.updateOne({ post_id: postId, user_id: viewer },
      { $setOnInsert: { post_id: postId, user_id: viewer, created_at: new Date() } }, { upsert: true });
  } else {
    await saved.deleteOne({ post_id: postId, user_id: viewer });
  }
  return getPost(viewer, postId);
}

async function listNotifications(viewer, query) {
  const { page, limit, skip } = pagination({ limit: 30, ...query });
  const collection = getCollection('Notification');
  const filter = { recipient_id: viewer };
  const [rows, total, unread] = await Promise.all([
    collection.find(filter).sort({ created_at: -1, id: 1 }).skip(skip).limit(limit).toArray(),
    collection.countDocuments(filter),
    collection.countDocuments({ ...filter, is_read: false }),
  ]);
  const users = await getCollection('User').find({ id: { $in: [...new Set(rows.map(n => n.actor_id))] } },
    { projection: PUBLIC_USER_FIELDS }).toArray();
  const byId = new Map(users.map(u => [u.id, u]));
  const data = rows.map(n => ({
    id: n.id, type: n.type, post_id: n.post_id || null, actor_id: n.actor_id,
    actor: byId.get(n.actor_id) || { id: n.actor_id, full_name: 'Deleted user' },
    is_read: !!n.is_read, created_at: n.created_at,
  }));
  return { data, unread_count: unread, pagination: { page, limit, total, has_more: skip + limit < total } };
}

// The recipient is part of every filter, so nobody can read another user's notification.
async function markRead(viewer, id) {
  validateId(id);
  const result = await getCollection('Notification').updateOne(
    { id, recipient_id: viewer }, { $set: { is_read: true } });
  if (!result.matchedCount) throw new AppError('Notification not found.', 404);
  return { id, is_read: true };
}

async function markAllRead(viewer) {
  const result = await getCollection('Notification').updateMany(
    { recipient_id: viewer, is_read: false }, { $set: { is_read: true } });
  return { updated: result.modifiedCount };
}

module.exports = {
  feed, getPost, listLikes, setLike, setSaved, listNotifications, markRead, markAllRead,
};
