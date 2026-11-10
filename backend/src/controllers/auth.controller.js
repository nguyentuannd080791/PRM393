// backend/src/controllers/auth.controller.js
const authService = require('../services/auth.service');
const { successResponse } = require('../utils/response');

async function register(req, res, next) {
  try {
    const data = await authService.registerUser(req.body);
    return successResponse(res, data, 201, 'User registered successfully');
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const data = await authService.loginUser(req.body);
    return successResponse(res, data, 200);
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    await authService.logoutUser(req.user.userId);
    return successResponse(res, null, 200, 'Logged out successfully');
  } catch (err) {
    next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const { current_password, new_password } = req.body;
    const result = await authService.changePassword(req.user.userId, { current_password, new_password });
    return successResponse(res, { token: result.token }, 200, result.message || 'Password updated successfully');
  } catch (err) {
    next(err);
  }
}

async function getMe(req, res, next) {
  try {
    const user = await authService.getCurrentUserProfile(req.user.userId);
    return successResponse(res, { user }, 200);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  login,
  logout,
  changePassword,
  getMe,
};
