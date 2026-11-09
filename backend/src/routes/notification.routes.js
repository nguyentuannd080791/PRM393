// Member 1: Notifications (SCR03).
const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireUser } = require('../services/friends.service');
const c = require('../controllers/feed.controller');

router.use(auth);
router.use(async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
});
router.get('/', c.notifications);
router.patch('/read-all', c.markAllRead); // must precede /:id/read
router.patch('/:id/read', c.markRead);
module.exports = router;
