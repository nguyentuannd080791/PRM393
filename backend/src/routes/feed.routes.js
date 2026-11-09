// Member 1: Home Feed (SCR01) and Post Detail (SCR02) APIs.
const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireUser } = require('../services/friends.service');
const c = require('../controllers/feed.controller');

router.use(auth);
router.use(async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
});
router.get('/', c.feed);
router.get('/posts/:id', c.getPost);
router.get('/posts/:id/likes', c.likes);
router.put('/posts/:id/like', c.like);
router.delete('/posts/:id/like', c.unlike);
router.put('/posts/:id/save', c.save);
router.delete('/posts/:id/save', c.unsave);
module.exports = router;
