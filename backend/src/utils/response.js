// backend/src/utils/response.js

function successResponse(res, data, statusCode = 200, message = null) {
  const body = { success: true };
  if (message) body.message = message;
  if (data !== undefined && data !== null) body.data = data;
  return res.status(statusCode).json(body);
}

function errorResponse(res, message, statusCode = 400, details = null) {
  const body = {
    success: false,
    message,
  };
  if (details) body.details = details;
  return res.status(statusCode).json(body);
}

function paginatedResponse(res, data, pagination, statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    data,
    pagination,
  });
}

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse,
};
