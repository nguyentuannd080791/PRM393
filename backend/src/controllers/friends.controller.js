const service = require('../services/friends.service');
const { successResponse } = require('../utils/response');

const handle = require('../middleware/async_handler');

exports.list = kind => handle(async (req, res) => {
  const result = await service.listRelationships(req.user.id, kind, req.query);
  res.json({ success: true, ...result });
});
exports.status = handle(async (req, res) => successResponse(res,
  await service.getStatus(req.user.id, req.params.userId)));
exports.send = handle(async (req, res) => successResponse(res,
  await service.sendRequest(req.user.id, req.body.receiver_id), 201, 'Friend request sent.'));
exports.change = action => handle(async (req, res) => successResponse(res,
  await service.changeRequest(req.user.id, req.params.id, action)));
