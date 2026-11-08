// backend/src/services/auth.service.js
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { AppError } = require('../middlewares/error.middleware');
const { MSG } = require('../utils/messages');
const {
  isValidEmail,
  isValidPhone,
  isValidPassword,
  isAtLeast13YearsOld,
  normalizeGender,
} = require('../utils/validation');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_fb_clone_course_project_jwt_key_2026_prm393';
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
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

/**
 * UC01: Register Account
 */
async function registerUser({ full_name, email, phone, password, birthday, gender, city, workplace, bio }) {
  // 1. Validate full_name
  if (!full_name || typeof full_name !== 'string' || full_name.trim().length === 0) {
    throw new AppError('Full name is required.', 400);
  }
  if (full_name.trim().length > 100) {
    throw new AppError('Full name must be at most 100 characters.', 400);
  }

  // 2. Validate email and phone (BR-01)
  const trimmedEmail = email ? email.trim().toLowerCase() : null;
  const trimmedPhone = phone ? phone.trim().replace(/[\s-]/g, '') : null;

  if (!trimmedEmail && !trimmedPhone) {
    throw new AppError('Either email or phone is required.', 400);
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

  // 4. Validate age (BR-03)
  if (!birthday || !isAtLeast13YearsOld(birthday)) {
    throw new AppError('You must be at least 13 years old to register.', 400);
  }

  // 5. Check uniqueness against "User" table (BR-01)
  const existingUserCheck = await db.query(
    `SELECT id, email, phone FROM "User" 
     WHERE ($1::varchar IS NOT NULL AND email = $1) 
        OR ($2::varchar IS NOT NULL AND phone = $2) 
     LIMIT 1;`,
    [trimmedEmail, trimmedPhone]
  );

  if (existingUserCheck.rows.length > 0) {
    throw new AppError(MSG.ACCOUNT_EXISTS, 409); // MSG-03: 409 Conflict
  }

  // 6. Hash password with bcrypt
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);
  const normalizedGender = normalizeGender(gender);

  // 7. Insert into "User" table
  const insertSql = `
    INSERT INTO "User" (
      full_name, email, phone, password_hash, birthday, gender, city, workplace, bio
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    RETURNING id, full_name, email, phone, birthday, gender, avatar_url, cover_url, bio, city, workplace, created_at;
  `;

  const result = await db.query(insertSql, [
    full_name.trim(),
    trimmedEmail,
    trimmedPhone,
    passwordHash,
    birthday,
    normalizedGender,
    city ? city.trim() : null,
    workplace ? workplace.trim() : null,
    bio ? bio.trim() : null,
  ]);

  const newUser = result.rows[0];
  const token = generateToken(newUser);

  return {
    user: newUser,
    token,
  };
}

/**
 * UC02: Login User
 */
async function loginUser({ identifier, email, phone, password }) {
  const targetIdentifier = (identifier || email || phone || '').trim();
  if (!targetIdentifier || !password) {
    throw new AppError('Identifier (email or phone) and password are required.', 400);
  }

  // 1. Check BR-04 lockout status
  checkLockout(targetIdentifier);

  // 2. Query user by email or phone
  const userResult = await db.query(
    `SELECT * FROM "User" 
     WHERE email = LOWER($1) OR phone = $1 
     LIMIT 1;`,
    [targetIdentifier]
  );

  if (userResult.rows.length === 0) {
    recordFailedLogin(targetIdentifier);
    throw new AppError(MSG.INVALID_CREDENTIALS, 401); // MSG-04: 401 Unauthorized
  }

  const user = userResult.rows[0];

  // 3. Verify bcrypt password hash
  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    recordFailedLogin(targetIdentifier);
    throw new AppError(MSG.INVALID_CREDENTIALS, 401); // MSG-04: 401 Unauthorized
  }

  // 4. Success: clear failed login counter
  clearFailedLogin(targetIdentifier);

  // 5. Exclude password_hash from response
  delete user.password_hash;
  const token = generateToken(user);

  return {
    user,
    token,
  };
}

/**
 * UC04: Forgot Password
 */
async function forgotPassword({ identifier, email, new_password }) {
  const targetIdentifier = (identifier || email || '').trim();
  if (!targetIdentifier) {
    throw new AppError('Email or phone identifier is required.', 400);
  }

  // Direct reset branch: new_password provided in body
  if (new_password) {
    if (!isValidPassword(new_password)) {
      throw new AppError(
        'Password must be at least 8 characters with at least one letter and one number.',
        400
      );
    }

    const salt = await bcrypt.genSalt(10);
    const newHash = await bcrypt.hash(new_password, salt);

    const updateRes = await db.query(
      `UPDATE "User" SET password_hash = $1 
       WHERE email = LOWER($2) OR phone = $2 
       RETURNING id;`,
      [newHash, targetIdentifier]
    );

    if (updateRes.rows.length === 0) {
      throw new AppError('User not found with provided identifier.', 404);
    }

    return { message: 'Password updated successfully' };
  }

  // Link dispatch branch: always return MSG-06 to prevent user enumeration
  return { message: MSG.RESET_LINK_SENT };
}

/**
 * UC05: Get Current User Profile (GET /api/auth/me)
 */
async function getCurrentUserProfile(userId) {
  const result = await db.query(
    `SELECT id, full_name, email, phone, birthday, gender, avatar_url, cover_url, bio, city, workplace, created_at 
     FROM "User" 
     WHERE id = $1;`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new AppError('User profile not found.', 404);
  }

  return result.rows[0];
}

module.exports = {
  registerUser,
  loginUser,
  forgotPassword,
  getCurrentUserProfile,
  checkLockout,
  recordFailedLogin,
  clearFailedLogin,
};
