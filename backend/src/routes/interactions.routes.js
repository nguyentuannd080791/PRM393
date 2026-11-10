// Member 3: Comments, Liked Posts, Saved Posts. Mounted at /api, so auth is per route.
const router = require('express').Router();
const auth = require('../middleware/auth');
const handle = require('../middleware/async_handler');
const { requireUser } = require('../services/friends.service');
const s = require('../services/interactions.service');

const signedIn = [auth, async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
}];

router.get('/posts/:id/comments', signedIn, handle(async (req, res) =>
  res.json({ success: true, ...await s.listComments(req.user.id, req.params.id, req.query) })));
router.post('/posts/:id/comments', signedIn, handle(async (req, res) =>
  res.status(201).json({ success: true, data: await s.addComment(req.user.id, req.params.id, req.body) })));
router.delete('/comments/:id', signedIn, handle(async (req, res) =>
  res.json({ success: true, data: await s.deleteComment(req.user.id, req.params.id) })));
router.get('/me/liked-posts', signedIn, handle(async (req, res) =>
  res.json({ success: true, ...await s.likedPosts(req.user.id, req.query) })));
router.get('/me/saved-posts', signedIn, handle(async (req, res) =>
  res.json({ success: true, ...await s.savedPosts(req.user.id, req.query) })));

module.exports = router;
