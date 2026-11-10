const router = require('express').Router();
const auth = require('../middleware/auth');
const handle = require('../middleware/async_handler');
const service = require('../services/posts.service');
const { requireUser } = require('../services/friends.service');

router.use(auth);
router.use(async (req, res, next) => {
  try {
    await requireUser(req.user.id);
    next();
  } catch (error) {
    next(error);
  }
});

router.get('/users/:userId', handle(async (req, res) => {
  res.json({ success: true, ...await service.listUserPosts(req.user.id, req.params.userId, req.query) });
}));
router.post('/', handle(async (req, res) => {
  res.status(201).json({ success: true, data: await service.createPost(req.user.id, req.body) });
}));
router.get('/:id/insights', handle(async (req, res) => {
  res.json({ success: true, data: await service.getInsights(req.user.id, req.params.id) });
}));
router.put('/:id', handle(async (req, res) => {
  res.json({ success: true, data: await service.updatePost(req.user.id, req.params.id, req.body) });
}));
router.delete('/:id', handle(async (req, res) => {
  res.json({ success: true, data: await service.deletePost(req.user.id, req.params.id) });
}));

module.exports = router;
