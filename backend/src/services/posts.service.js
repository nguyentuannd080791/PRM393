const crypto = require('crypto');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { validateId, pagination, pairKey, requireUser } = require('./friends.service');

const ACTIVE_POST = {
  is_deleted: { $ne: true },
  isDeleted: { $ne: true },
  deleted_at: null,
};

function validateContent(value) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > 5000) {
    throw new AppError('Post content must contain 1–5000 characters.', 400);
  }
  return value.trim();
}

function validateAudience(value) {
  if (value === undefined) return undefined;
  if (!['public', 'friends', 'only_me'].includes(value)) {
    throw new AppError('Audience must be public, friends, or only_me.', 400);
  }
  return value;
}

async function requireOwnedPost(viewer, id) {
  validateId(id);
  const post = await getCollection('Post').findOne({ id, ...ACTIVE_POST });
  if (!post) throw new AppError('Post not found.', 404);
  if (post.author_id !== viewer) {
    throw new AppError('You can only manage your own posts.', 403);
  }
  return post;
}

async function countsForPosts(posts) {
  const ids = posts.map(post => post.id);
  if (!ids.length) return new Map();
  const [reactions, comments] = await Promise.all([
    getCollection('Reaction').aggregate([
      { $match: { post_id: { $in: ids } } },
      { $group: { _id: '$post_id', count: { $sum: 1 } } },
    ]).toArray(),
    getCollection('Comment').aggregate([
      { $match: { post_id: { $in: ids }, is_deleted: { $ne: true }, isDeleted: { $ne: true } } },
      { $group: { _id: '$post_id', count: { $sum: 1 } } },
    ]).toArray(),
  ]);
  const counts = new Map(ids.map(id => [id, { likes: 0, comments: 0 }]));
  for (const row of reactions) counts.get(row._id).likes = row.count;
  for (const row of comments) counts.get(row._id).comments = row.count;
  return counts;
}

async function listUserPosts(viewer, userId, query) {
  validateId(userId);
  const author = await requireUser(userId);
  const { page, limit, skip } = pagination(query);
  let visibility = {};
  if (viewer !== userId) {
    const friendship = await getCollection('Friendship').findOne({
      pair: pairKey(viewer, userId),
      status: 'accepted',
    });
    visibility = friendship
      ? { audience: { $in: ['public', 'friends', null] } }
      : { $or: [{ audience: 'public' }, { audience: null }, { audience: { $exists: false } }] };
  }
  const filter = { author_id: userId, ...ACTIVE_POST, ...visibility };
  const collection = getCollection('Post');
  const [posts, total] = await Promise.all([
    collection.find(filter, {
      projection: { _id: 0, id: 1, author_id: 1, content: 1, media_urls: 1, audience: 1, created_at: 1, updated_at: 1 },
    }).sort({ created_at: -1, id: 1 }).skip(skip).limit(limit).toArray(),
    collection.countDocuments(filter),
  ]);
  const counts = await countsForPosts(posts);
  const data = posts.map(post => ({
    ...post,
    author: { id: author.id, full_name: author.full_name },
    likes: counts.get(post.id).likes,
    comments: counts.get(post.id).comments,
  }));
  return { data, pagination: { page, limit, total, has_more: skip + limit < total } };
}

async function createPost(viewer, body) {
  const content = validateContent(body?.content);
  const audience = validateAudience(body?.audience) ?? 'public';
  const now = new Date();
  const post = {
    id: crypto.randomUUID(),
    author_id: viewer,
    content,
    audience,
    media_urls: [],
    shared_post_id: null,
    is_deleted: false,
    created_at: now,
    updated_at: now,
  };
  await getCollection('Post').insertOne({ _id: post.id, ...post });
  return { ...post, likes: 0, comments: 0 };
}

async function updatePost(viewer, id, body) {
  const post = await requireOwnedPost(viewer, id);
  const updates = { updated_at: new Date() };
  if (Object.hasOwn(body ?? {}, 'content')) updates.content = validateContent(body.content);
  if (Object.hasOwn(body ?? {}, 'audience')) updates.audience = validateAudience(body.audience);
  if (Object.keys(updates).length === 1) {
    throw new AppError('Provide content or audience to update.', 400);
  }
  await getCollection('Post').updateOne({ id, author_id: viewer }, { $set: updates });
  return { ...post, ...updates };
}

async function deletePost(viewer, id) {
  await requireOwnedPost(viewer, id);
  await getCollection('Post').updateOne(
    { id, author_id: viewer, ...ACTIVE_POST },
    { $set: { is_deleted: true, deleted_at: new Date(), updated_at: new Date() } },
  );
  return { id, deleted: true };
}

async function getInsights(viewer, id) {
  const post = await requireOwnedPost(viewer, id);
  const [likes, comments] = await Promise.all([
    getCollection('Reaction').countDocuments({ post_id: id }),
    getCollection('Comment').countDocuments({
      post_id: id,
      is_deleted: { $ne: true },
      isDeleted: { $ne: true },
    }),
  ]);
  const [reactionRows, commentRows] = await Promise.all([
    getCollection('Reaction').find(
      { post_id: id },
      { projection: { _id: 0, user_id: 1, created_at: 1 } },
    ).sort({ created_at: -1 }).limit(5).toArray(),
    getCollection('Comment').find(
      {
        post_id: id,
        is_deleted: { $ne: true },
        isDeleted: { $ne: true },
      },
      { projection: { _id: 0, author_id: 1, user_id: 1, created_at: 1 } },
    ).sort({ created_at: -1 }).limit(5).toArray(),
  ]);
  const activities = [
    ...reactionRows.map(row => ({
      user_id: row.user_id,
      action: 'liked',
      created_at: row.created_at,
    })),
    ...commentRows.map(row => ({
      user_id: row.author_id || row.user_id,
      action: 'commented',
      created_at: row.created_at,
    })),
  ].sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0))
    .slice(0, 5);
  const actors = await getCollection('User').find(
    { id: { $in: activities.map(activity => activity.user_id).filter(Boolean) } },
    { projection: { _id: 0, id: 1, full_name: 1 } },
  ).toArray();
  const names = new Map(actors.map(actor => [actor.id, actor.full_name]));
  const author = await requireUser(viewer);
  return {
    post_id: id,
    content: post.content || '',
    created_at: post.created_at,
    author: { id: author.id, full_name: author.full_name },
    likes,
    comments,
    engagement: likes + comments,
    recent_activity: activities.map(activity => ({
      actor_name: names.get(activity.user_id) || 'Someone',
      action: activity.action,
      created_at: activity.created_at,
    })),
  };
}

module.exports = {
  listUserPosts,
  createPost,
  updatePost,
  deletePost,
  getInsights,
};
