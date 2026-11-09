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

  // MongoDB Code 11000: Duplicate key error (or PostgreSQL 23505)
  if (err.code === 11000 || err.code === '23505') {
    const errorMsg = err.message || err.detail || '';
    const keyPattern = err.keyPattern || {};

    if (keyPattern.email || errorMsg.includes('email') || errorMsg.includes('idx_user_email')) {
      return res.status(409).json({
        success: false,
        message: 'Email is already registered',
      });
    }
    if (keyPattern.phone || errorMsg.includes('phone') || errorMsg.includes('idx_user_phone')) {
      return res.status(409).json({
        success: false,
        message: 'Phone number is already registered',
      });
    }
    if (keyPattern.pair || errorMsg.includes('friendship') || errorMsg.includes('idx_friendship_bidirectional_pair')) {
      return res.status(409).json({
        success: false,
        message: 'A friendship or friend request already exists between these users',
      });
    }
    if (errorMsg.includes('Reaction') || errorMsg.includes('idx_reaction_post_user_unique')) {
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
