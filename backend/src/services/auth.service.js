// backend/src/services/auth.service.js
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { getCollection } = require('../config/database');
const { AppError } = require('../middleware/error');
const { MSG } = require('../utils/messages');
const { jwtSecret } = require('../config/jwt');
const {
  isValidEmail,
  isValidPhone,
  isValidPassword,
  isValidBio,
  isAtLeast13YearsOld,
  normalizeGender,
} = require('../utils/validation');

const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

// =============================================================================
// BR-04: In-Memory Login Attempt & Lockout Tracker
// Map<identifier, { attempts: number, lockedUntil: number | null }>
// =============================================================================
const loginAttempts = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 5 * 60 * 1000; // 5 minutes

function checkLockout(identifier) {
  const key = identifier.toLowerCase().trim();
  const record = loginAttempts.get(key);
  if (!record) return;

  if (record.lockedUntil) {
    if (Date.now() < record.lockedUntil) {
      throw new AppError(MSG.TOO_MANY_ATTEMPTS, 429); // MSG-05: 429 Too Many Requests
    } else {
      // Lockout expired, reset counter
      loginAttempts.delete(key);
    }
  }
}

function recordFailedLogin(identifier) {
  const key = identifier.toLowerCase().trim();
  const record = loginAttempts.get(key) || { attempts: 0, lockedUntil: null };
  record.attempts += 1;

  if (record.attempts >= MAX_FAILED_ATTEMPTS) {
    record.lockedUntil = Date.now() + LOCKOUT_DURATION_MS;
    loginAttempts.set(key, record);
    throw new AppError(MSG.TOO_MANY_ATTEMPTS, 429);
  }

  loginAttempts.set(key, record);
}

function clearFailedLogin(identifier) {
  loginAttempts.delete(identifier.toLowerCase().trim());
}


// Every client-supplied field must be a string of sane length before any .trim()/bcrypt call.
const CONTROL_CHARS = /[\u0000-\u001f\u007f]/;
function text(value, field, max) {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== 'string') throw new AppError(`${field} must be text.`, 400);
  if (value.length > max) throw new AppError(`${field} is too long (max ${max} characters).`, 400);
  return value;
}

/**
 * Generate JWT token for authenticated user
 */
function generateToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      id: user.id,
      email: user.email,
      full_name: user.full_name,
    },
    jwtSecret(),
    { expiresIn: JWT_EXPIRES_IN }
  );
}

/**
 * UC01: Register Account
 */
async function registerUser({ full_name, email, phone, password, birthday, birth_date, gender, city, workplace, bio }) {
  full_name = text(full_name, 'Full name', 200);
  email = text(email, 'Email', 320);
  phone = text(phone, 'Phone', 40);
  password = text(password, 'Password', 128);
  gender = text(gender, 'Gender', 20);
  city = text(city, 'City', 200);
  workplace = text(workplace, 'Workplace', 200);
  bio = text(bio, 'Bio', 1000);
  const userBirthday = text(birthday || birth_date, 'Birthday', 40);
  // 1. Validate full_name
  if (!full_name || typeof full_name !== 'string' || full_name.trim().length === 0) {
    throw new AppError('Full name is required.', 400);
  }
  if (full_name.trim().length > 100) {
    throw new AppError('Full name must be at most 100 characters.', 400);
  }
  if (CONTROL_CHARS.test(full_name)) {
    throw new AppError('Full name contains invalid characters.', 400);
  }

  // 2. Validate email and phone (BR-01)
  const trimmedEmail = email ? email.trim().toLowerCase() : null;
  const trimmedPhone = phone ? phone.trim().replace(/[\s-]/g, '') : null;

  if (!trimmedPhone) {
    throw new AppError('Please enter the required information.', 400);
  }
  if (trimmedEmail && !isValidEmail(trimmedEmail)) {
    throw new AppError('Invalid email format.', 400);
  }
  if (trimmedPhone && !isValidPhone(trimmedPhone)) {
    throw new AppError('Invalid phone number format.', 400);
  }

  // 3. Validate password complexity (BR-02)
  if (!isValidPassword(password)) {
    throw new AppError(
      'Password must be at least 8 characters with at least one letter and one number.',
      400
    );
  }

  // Validate bio if provided (BR-14)
  if (bio !== undefined && bio !== null) {
    if (!isValidBio(bio)) {
      throw new AppError('Bio cannot exceed 150 characters.', 400);
    }
  }

  // 4. Birthday is optional; when given, enforce the age rule (BR-03)
  if (userBirthday && !isAtLeast13YearsOld(userBirthday)) {
    throw new AppError('You must be at least 13 years old to register.', 400);
  }

  // 5. Check uniqueness against "User" collection (BR-01)
  const userColl = getCollection('User');
  const orConditions = [];
  if (trimmedEmail) orConditions.push({ email: trimmedEmail });
  if (trimmedPhone) orConditions.push({ phone: trimmedPhone });

  const existingUser = await userColl.findOne({ $or: orConditions });
  if (existingUser) {
    throw new AppError(MSG.ACCOUNT_EXISTS, 409); // MSG-03: 409 Conflict
  }

  // 6. Hash password with bcrypt
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);
  const normalizedGender = normalizeGender(gender);

  // 7. Insert into "User" collection
  const id = crypto.randomUUID();
  const newUser = {
    _id: id,
    id,
    full_name: full_name.trim(),
    email: trimmedEmail,
    phone: trimmedPhone,
    password_hash: passwordHash,
    birthday: userBirthday ? new Date(userBirthday) : null,
    gender: normalizedGender,
    avatar_url: null,
    cover_url: null,
    bio: bio ? bio.trim() : null,
    city: city ? city.trim() : null,
    workplace: workplace ? workplace.trim() : null,
    saved_post_ids: [],
    created_at: new Date(),
  };

  await userColl.insertOne(newUser);

  // Strip password_hash for return
  const safeUser = { ...newUser };
  delete safeUser.password_hash;
  delete safeUser._id;

  const token = generateToken(safeUser);

  return {
    user: safeUser,
    token,
  };
}

/**
 * UC02: Login User
 */
async function loginUser({ identifier, email, phone, password }) {
  identifier = text(identifier, 'Identifier', 320);
  email = text(email, 'Email', 320);
  phone = text(phone, 'Phone', 40);
  password = text(password, 'Password', 128);
  const targetIdentifier = (identifier || email || phone || '').trim();
  if (!targetIdentifier || !password) {
    throw new AppError('Identifier (email or phone) and password are required.', 400);
  }

  // 1. Check BR-04 lockout status
  checkLockout(targetIdentifier);

  // 2. Query user by email or phone
  const userColl = getCollection('User');
  const user = await userColl.findOne({
    $or: [
      { email: targetIdentifier.toLowerCase() },
      { phone: targetIdentifier },
    ],
  });

  if (!user) {
    recordFailedLogin(targetIdentifier);
    throw new AppError(MSG.INVALID_CREDENTIALS, 401); // MSG-04: 401 Unauthorized
  }

  // 3. Verify bcrypt password hash
  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    recordFailedLogin(targetIdentifier);
    throw new AppError(MSG.INVALID_CREDENTIALS, 401); // MSG-04: 401 Unauthorized
  }

  // 4. Success: clear failed login counter
  clearFailedLogin(targetIdentifier);

  // 5. Exclude password_hash and internal fields
  delete user.password_hash;
  delete user._id;

  const token = generateToken(user);

  return {
    user,
    token,
  };
}

/**
 * UC05: Get Current User Profile (GET /api/auth/me)
 */
async function getCurrentUserProfile(userId) {
  const userColl = getCollection('User');
  const user = await userColl.findOne({ id: userId });

  if (!user) {
    throw new AppError('User profile not found.', 404);
  }

  delete user.password_hash;
  delete user._id;
  return user;
}

/**
 * Change Password
 */
async function changePassword(userId, { current_password, new_password } = {}) {
  current_password = text(current_password, 'Current password', 128);
  new_password = text(new_password, 'New password', 128);
  if (!current_password || !new_password) {
    throw new AppError('Current password and new password are required.', 400);
  }

  if (!isValidPassword(new_password)) {
    throw new AppError(
      'Password must be at least 8 characters with at least one letter and one number.',
      400
    );
  }

  const userColl = getCollection('User');
  const user = await userColl.findOne({ id: userId });
  if (!user) {
    throw new AppError('User not found.', 404);
  }

  const isMatch = await bcrypt.compare(current_password, user.password_hash);
  if (!isMatch) {
    throw new AppError('Current password is incorrect.', 400);
  }

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(new_password, salt);

  await userColl.updateOne(
    { id: userId },
    { $set: { password_hash: passwordHash } }
  );

  return { message: 'Password updated successfully' };
}

module.exports = {
  registerUser,
  loginUser,
  changePassword,
  getCurrentUserProfile,
  checkLockout,
  recordFailedLogin,
  clearFailedLogin,
};
