// backend/src/middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/jwt');
const { getCollection } = require('../config/database');

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
  const secret = jwtSecret();

  jwt.verify(token, secret, async (err, decoded) => {
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
    try {
      // Revocation: logout / password change bump token_version, which kills older tokens.
      const record = await getCollection('User').findOne({ id: userId }, { projection: { token_version: 1 } });
      if (record && (record.token_version || 0) !== (decoded.tv || 0)) {
        return res.status(401).json({
          success: false,
          message: 'Session expired. Please log in again.',
        });
      }
    } catch (dbError) {
      return next(dbError);
    }
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
