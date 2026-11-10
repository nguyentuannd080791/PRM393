// Member 5: Profile (SCR13) and Edit Profile (SCR14). Shapes match frontend ProfileRepository.
const router = require('express').Router();
const auth = require('../middleware/auth');
const handle = require('../middleware/async_handler');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { validateProfilePayload } = require('../utils/validation');
const { requireUser, getStatus, validateId } = require('../services/friends.service');
const { enrich, friendIdsOf } = require('../services/feed.service');
const { listUserPosts } = require('../services/posts.service');

const PROFILE_FIELDS = { _id: 0, id: 1, full_name: 1, bio: 1, avatar_url: 1, created_at: 1 };

router.use(auth);
router.use(async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
});

// BR: a user may update only their own profile, so the target is always the token's user.
router.put('/profile', handle(async (req, res) => {
  const body = { full_name: req.body?.full_name, bio: req.body?.bio };
  if (body.full_name === undefined) throw new AppError('Please enter the required information.', 400);
  const check = validateProfilePayload(body);
  if (!check.valid) throw new AppError(check.message, 400);
  const bio = typeof body.bio === 'string' && body.bio.trim() ? body.bio.trim() : null;
  await getCollection('User').updateOne({ id: req.user.id },
    { $set: { full_name: body.full_name.trim(), bio, updated_at: new Date() } });
  const user = await getCollection('User').findOne({ id: req.user.id }, { projection: PROFILE_FIELDS });
  res.json({ success: true, message: 'Changes saved successfully.', data: { user } });
}));

router.get('/:id', handle(async (req, res) => {
  const id = validateId(req.params.id === 'me' ? req.user.id : req.params.id);
  const user = await getCollection('User').findOne({ id }, { projection: PROFILE_FIELDS });
  if (!user) throw new AppError('User not found.', 404);
  const [rel, theirs, mine] = await Promise.all([
    getStatus(req.user.id, id), friendIdsOf(id), friendIdsOf(req.user.id),
  ]);
  const mineSet = new Set(mine);
  res.json({ success: true, data: {
    user,
    relationship_status: rel.status,
    friends_count: theirs.length,
    mutual_friends_count: rel.status === 'self' ? 0 : theirs.filter(f => mineSet.has(f)).length,
  } });
}));

// Same visibility as Member 2's list, returned in the FeedPostView shape.
router.get('/:id/posts', handle(async (req, res) => {
  const { data, pagination } = await listUserPosts(req.user.id, req.params.id === 'me' ? req.user.id : req.params.id, req.query);
  const posts = (await enrich(req.user.id, data)).map(p => ({
    ...p, reaction_count: p.like_count, current_user_reaction: p.liked_by_me ? 'like' : null,
  }));
  res.json({ success: true, data: posts,
    pagination: { ...pagination, totalPages: Math.ceil(pagination.total / pagination.limit) } });
}));

module.exports = router;
