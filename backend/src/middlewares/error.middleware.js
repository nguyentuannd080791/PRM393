// backend/src/middlewares/error.middleware.js

class AppError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.statusCode = statusCode;
    this.status = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

function errorMiddleware(err, req, res, next) {
  if (process.env.NODE_ENV === 'development') {
    console.error(`[ERROR] ${req.method} ${req.url}:`, err);
  }

  // PostgreSQL Error Code 23505: Unique constraint violation (BR-01)
  if (err.code === '23505') {
    const detail = err.detail || '';
    if (detail.includes('email')) {
      return res.status(409).json({
        success: false,
        message: 'Email is already registered',
      });
    }
    if (detail.includes('phone')) {
      return res.status(409).json({
        success: false,
        message: 'Phone number is already registered',
      });
    }
    if (detail.includes('uq_friendship_direct_pair') || detail.includes('idx_friendship_bidirectional_pair')) {
      return res.status(409).json({
        success: false,
        message: 'A friendship or friend request already exists between these users',
      });
    }
    if (detail.includes('Reaction')) {
      return res.status(409).json({
        success: false,
        message: 'Reaction already exists for this post',
      });
    }
    return res.status(409).json({
      success: false,
      message: 'Resource already exists (unique constraint violation)',
    });
  }

  // PostgreSQL Error Code 23503: Foreign Key constraint violation
  if (err.code === '23503') {
    return res.status(400).json({
      success: false,
      message: 'Referenced entity does not exist',
      detail: err.detail,
    });
  }

  // PostgreSQL Error Code 23514: Check constraint violation
  if (err.code === '23514') {
    if (err.constraint === 'chk_friendship_no_self') {
      return res.status(400).json({
        success: false,
        message: 'Cannot send friend request to yourself',
      });
    }
    if (err.constraint === 'chk_post_audience') {
      return res.status(400).json({
        success: false,
        message: "Invalid audience value. Must be 'public', 'friends', or 'only_me'",
      });
    }
    if (err.constraint === 'chk_reaction_type') {
      return res.status(400).json({
        success: false,
        message: 'Invalid reaction type',
      });
    }
    return res.status(400).json({
      success: false,
      message: 'Validation check constraint failed',
    });
  }

  // PostgreSQL Error Code 22P02: Invalid text representation (e.g. invalid UUID format)
  if (err.code === '22P02') {
    return res.status(400).json({
      success: false,
      message: 'Invalid input syntax (e.g. malformed UUID)',
    });
  }

  // Custom HTTP status codes
  const status = err.statusCode || err.status || 500;
  const message = err.message || 'Internal server error';

  res.status(status).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
}

module.exports = errorMiddleware;
module.exports.AppError = AppError;
