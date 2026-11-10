const router = require('express').Router();
const auth = require('../middleware/auth');
const { requireUser } = require('../services/friends.service');
const controller = require('../controllers/search.controller');

router.use(auth);
router.use(async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
});
router.get('/users', controller.users);
router.get('/posts', controller.posts);
module.exports = router;
