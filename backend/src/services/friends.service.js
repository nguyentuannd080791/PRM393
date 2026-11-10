const crypto = require('crypto');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');

const PUBLIC_USER_FIELDS = { _id: 0, id: 1, full_name: 1, bio: 1 };
const pairKey = (a, b) => [a, b].sort().join(':');

function validateId(value) {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9-]{1,100}$/.test(value)) {
    throw new AppError('Invalid user or request ID.', 400);
  }
  return value;
}

function pagination(query = {}) {
  const page = query.page === undefined ? 1 : Number(query.page);
  const limit = query.limit === undefined ? 50 : Number(query.limit);
  if (!Number.isSafeInteger(page) || page < 1 || page > 10000 ||
      !Number.isSafeInteger(limit) || limit < 1 || limit > 100) {
    throw new AppError('page must be 1–10000 and limit must be 1–100.', 400);
  }
  return { page, limit, skip: (page - 1) * limit };
}

async function requireUser(id) {
  validateId(id);
  const user = await getCollection('User').findOne({ id }, { projection: PUBLIC_USER_FIELDS });
  if (!user) throw new AppError('User not found.', 404);
  return user;
}

function relationship(doc, viewer) {
  if (!doc || !['pending', 'accepted'].includes(doc.status)) {
    return { status: 'none', request_id: null };
  }
  return {
    status: doc.status === 'accepted' ? 'friends' :
      doc.requester_id === viewer ? 'pending_sent' : 'pending_received',
    request_id: doc.id,
  };
}

async function getStatus(viewer, other) {
  validateId(other);
  if (viewer === other) return { status: 'self', request_id: null };
  await requireUser(other);
  return relationship(await getCollection('Friendship').findOne({ pair: pairKey(viewer, other) }), viewer);
}

async function notify(request, type, recipient, actor) {
  // Deterministic event key makes notification creation idempotent.
  const key = `${request.id}:${type}`;
  try {
    await getCollection('Notification').updateOne({ _id: key }, { $setOnInsert: {
      id: crypto.randomUUID(), recipient_id: recipient, actor_id: actor,
      post_id: null, type, is_read: false, created_at: new Date(),
    } }, { upsert: true });
  } catch (error) {
    // A notification outage must not make a successful friendship action appear to fail.
    console.error('[Member4] Could not create notification:', error.message);
  }
}

async function sendRequest(viewer, receiverId) {
  validateId(receiverId);
  if (viewer === receiverId) throw new AppError('You cannot send a request to yourself.', 400);
  await requireUser(receiverId);
  const collection = getCollection('Friendship');
  const pair = pairKey(viewer, receiverId);
  const existing = await collection.findOne({ pair });
  const fields = {
    id: crypto.randomUUID(), pair, requester_id: viewer, receiver_id: receiverId,
    status: 'pending', created_at: new Date(), responded_at: null,
  };
  if (existing) {
    if (['pending', 'accepted'].includes(existing.status)) {
      throw new AppError('Request already exists.', 409);
    }
    // Compare-and-set also prevents two concurrent retries or stale actions succeeding.
    const result = await collection.updateOne(
      { _id: existing._id, id: existing.id, status: existing.status }, { $set: fields });
    if (!result.modifiedCount) throw new AppError('Relationship changed. Refresh and try again.', 409);
  } else {
    try {
      await collection.insertOne({ _id: fields.id, ...fields });
    } catch (error) {
      if (error.code === 11000) throw new AppError('Request already exists.', 409);
      throw error;
    }
  }
  await notify(fields, 'friend_request', receiverId, viewer);
  return { ...fields, user: await requireUser(receiverId) };
}

async function changeRequest(viewer, id, action) {
  validateId(id);
  const collection = getCollection('Friendship');
  const current = await collection.findOne({ id });
  if (!current) throw new AppError('Friend request not found.', 404);
  const owner = action === 'cancel' ? 'requester_id' : 'receiver_id';
  if (current[owner] !== viewer) throw new AppError('You cannot perform this action on this request.', 403);
  if (current.status !== 'pending') throw new AppError('Only pending requests can be changed.', 409);
  const status = { accept: 'accepted', decline: 'rejected', cancel: 'canceled' }[action];
  if (!status) throw new AppError('Invalid request action.', 400);
  const respondedAt = new Date();
  const result = await collection.updateOne(
    { id, status: 'pending', [owner]: viewer },
    { $set: { status, responded_at: respondedAt } });
  if (!result.modifiedCount) throw new AppError('Request already changed. Refresh and try again.', 409);
  if (action === 'accept') await notify(current, 'friend_accept', current.requester_id, viewer);
  return { id, status, responded_at: respondedAt };
}

// Unfriend: either friend may end an accepted friendship. The row is deleted (not flagged) so a
// fresh request can be sent later; the filter includes status so pending requests are untouched.
async function removeFriend(viewer, otherId) {
  validateId(otherId);
  if (viewer === otherId) throw new AppError('You cannot unfriend yourself.', 400);
  await requireUser(otherId);
  const result = await getCollection('Friendship').deleteOne({
    pair: pairKey(viewer, otherId), status: 'accepted',
  });
  if (!result.deletedCount) throw new AppError('You are not friends with this user.', 404);
  return { user_id: otherId, status: 'none' };
}

async function listRelationships(viewer, kind, query) {
  const { page, limit, skip } = pagination(query);
  const isFriends = kind === 'friends';
  const filter = isFriends
    ? { status: 'accepted', $or: [{ requester_id: viewer }, { receiver_id: viewer }] }
    : { status: 'pending', [kind === 'received' ? 'receiver_id' : 'requester_id']: viewer };
  const collection = getCollection('Friendship');
  const [rows, total] = await Promise.all([
    collection.find(filter).sort({ created_at: -1, id: 1 }).skip(skip).limit(limit).toArray(),
    collection.countDocuments(filter),
  ]);
  const ids = rows.map(row => row.requester_id === viewer ? row.receiver_id : row.requester_id);
  const users = await getCollection('User').find({ id: { $in: ids } }, { projection: PUBLIC_USER_FIELDS }).toArray();
  const byId = new Map(users.map(user => [user.id, user]));
  const data = rows.map((row, index) => ({
    id: row.id, status: row.status, created_at: row.created_at,
    responded_at: row.responded_at, user: byId.get(ids[index]),
  })).filter(row => row.user);
  return { data, pagination: { page, limit, total, has_more: skip + limit < total } };
}

module.exports = {
  PUBLIC_USER_FIELDS, pairKey, validateId, pagination, requireUser, relationship,
  getStatus, sendRequest, changeRequest, removeFriend, listRelationships,
};
