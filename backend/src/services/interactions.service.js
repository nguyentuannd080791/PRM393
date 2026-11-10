// Member 3: Comments (SCR07), Liked Posts (SCR08), Saved Posts (SCR09).
const crypto = require('crypto');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { validateCommentPayload } = require('../utils/validation');
const { PUBLIC_USER_FIELDS, validateId, pagination } = require('./friends.service');
const { enrich, visiblePost, visibleFilter, friendIdsOf } = require('./feed.service');

const page = (data, p, total) => ({ data, pagination: { ...p, total, has_more: p.skip + p.limit < total } });

async function listComments(viewer, postId, query) {
  await visiblePost(viewer, postId);
  const p = pagination({ limit: 100, ...query });
  const comments = getCollection('Comment');
  const [rows, total] = await Promise.all([
    comments.find({ post_id: postId }).sort({ created_at: 1, id: 1 }).skip(p.skip).limit(p.limit).toArray(),
    comments.countDocuments({ post_id: postId }),
  ]);
  const authorOf = c => c.author_id || c.user_id;
  const users = await getCollection('User').find({ id: { $in: [...new Set(rows.map(authorOf))] } },
    { projection: PUBLIC_USER_FIELDS }).toArray();
  const byId = new Map(users.map(u => [u.id, u]));
  const data = rows.map(c => ({
    id: c.id, post_id: c.post_id, content: c.content, created_at: c.created_at,
    author: byId.get(authorOf(c)) || { id: authorOf(c), full_name: 'Deleted user' },
    is_mine: authorOf(c) === viewer,
  }));
  return page(data, { page: p.page, limit: p.limit, skip: p.skip }, total);
}

async function addComment(viewer, postId, body) {
  const check = validateCommentPayload(body?.content);
  if (!check.valid) throw new AppError(check.message, 400);
  const post = await visiblePost(viewer, postId);
  const comment = {
    id: crypto.randomUUID(), post_id: postId, author_id: viewer, content: check.text, created_at: new Date(),
  };
  await getCollection('Comment').insertOne({ _id: comment.id, ...comment });
  if (post.author_id !== viewer) {
    try {
      await getCollection('Notification').insertOne({
        _id: `comment:${comment.id}`, id: crypto.randomUUID(), recipient_id: post.author_id, actor_id: viewer,
        post_id: postId, type: 'comment', is_read: false, created_at: new Date(),
      });
    } catch (error) { console.error('[Member3] Could not create notification:', error.message); }
  }
  const author = await getCollection('User').findOne({ id: viewer }, { projection: PUBLIC_USER_FIELDS });
  return { ...comment, author, is_mine: true };
}

// BR02: only the comment author may delete it.
async function deleteComment(viewer, id) {
  validateId(id);
  const comments = getCollection('Comment');
  const comment = await comments.findOne({ id });
  if (!comment) throw new AppError('Comment not found.', 404);
  if ((comment.author_id || comment.user_id) !== viewer) {
    throw new AppError('You can only delete your own comments.', 403);
  }
  await comments.deleteOne({ id });
  await getCollection('Notification').deleteOne({ _id: `comment:${id}` });
  return { id, deleted: true };
}

// Posts the viewer liked or saved, newest action first, still visible to the viewer.
async function listMarked(collection, viewer, query) {
  const p = pagination({ limit: 50, ...query });
  const marks = getCollection(collection);
  const [rows, total] = await Promise.all([
    marks.find({ user_id: viewer }).sort({ created_at: -1, post_id: 1 }).skip(p.skip).limit(p.limit).toArray(),
    marks.countDocuments({ user_id: viewer }),
  ]);
  const ids = rows.map(r => r.post_id);
  const posts = await getCollection('Post').find({
    $and: [{ id: { $in: ids } }, visibleFilter(viewer, await friendIdsOf(viewer))],
  }).toArray();
  const byId = new Map(posts.map(post => [post.id, post]));
  const data = await enrich(viewer, ids.map(id => byId.get(id)).filter(Boolean));
  return page(data, { page: p.page, limit: p.limit, skip: p.skip }, total);
}

module.exports = {
  listComments, addComment, deleteComment,
  likedPosts: (viewer, query) => listMarked('Reaction', viewer, query),
  savedPosts: (viewer, query) => listMarked('SavedPost', viewer, query),
};
