const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/friends.controller');
const { requireUser } = require('../services/friends.service');

router.use(auth);
router.use(async (req, res, next) => {
  try { await requireUser(req.user.id); next(); } catch (error) { next(error); }
});
router.get('/', controller.list('friends'));
router.get('/requests/received', controller.list('received'));
router.get('/requests/sent', controller.list('sent'));
router.get('/status/:userId', controller.status);
router.post('/requests', controller.send);
router.patch('/requests/:id/accept', controller.change('accept'));
router.patch('/requests/:id/decline', controller.change('decline'));
router.patch('/requests/:id/cancel', controller.change('cancel'));

module.exports = router;
