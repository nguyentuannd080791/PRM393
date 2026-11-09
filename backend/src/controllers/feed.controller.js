const service = require('../services/feed.service');
const handle = require('../middleware/async_handler');
const { successResponse } = require('../utils/response');

// Paged list: fn(viewer, ...pathParams, query).
const list = (fn, ...params) => handle(async (req, res) =>
  res.json({ success: true, ...await fn(req.user.id, ...params.map(p => req.params[p]), req.query) }));
// Single item addressed by :id: fn(viewer, id, ...extra).
const one = (fn, ...extra) => handle(async (req, res) =>
  successResponse(res, await fn(req.user.id, req.params.id, ...extra)));

exports.feed = list(service.feed);
exports.getPost = one(service.getPost);
exports.likes = list(service.listLikes, 'id');
exports.like = one(service.setLike, true);
exports.unlike = one(service.setLike, false);
exports.save = one(service.setSaved, true);
exports.unsave = one(service.setSaved, false);
exports.notifications = list(service.listNotifications);
exports.markRead = one(service.markRead);
exports.markAllRead = handle(async (req, res) =>
  successResponse(res, await service.markAllRead(req.user.id)));
