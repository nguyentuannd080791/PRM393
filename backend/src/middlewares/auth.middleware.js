// backend/src/middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || typeof authHeader !== 'string') {
    return res.status(401).json({
      success: false,
      message: 'Authentication required. Missing Bearer token.',
    });
  }

  const parts = authHeader.trim().split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
    return res.status(401).json({
      success: false,
      message: 'Invalid authorization format. Must be: Bearer <token>',
    });
  }

  const token = parts[1];
  const secret = process.env.JWT_SECRET || 'super_secret_fb_clone_course_project_jwt_key_2026_prm393';

  jwt.verify(token, secret, (err, decoded) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please log in again.',
        });
      }
      return res.status(401).json({
        success: false,
        message: 'Invalid token. Authorization denied.',
      });
    }

    const userId = decoded.userId || decoded.id;
    req.user = {
      userId,
      id: userId,
      email: decoded.email,
      full_name: decoded.full_name,
    };
    next();
  });
}

module.exports = authMiddleware;
