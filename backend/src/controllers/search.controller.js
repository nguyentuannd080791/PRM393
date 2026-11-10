const { search } = require('../services/search.service');
const handle = require('../middleware/async_handler');
exports.users = handle(async (req, res) => {
  res.json({ success: true, ...await search(req.user.id, 'users', req.query) });
});
exports.posts = handle(async (req, res) => {
  res.json({ success: true, ...await search(req.user.id, 'posts', req.query) });
});
