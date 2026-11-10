// backend/src/utils/validation.js
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_REGEX = /^\+?[0-9]{9,15}$/;

// BR-02: Min 8 chars, at least 1 letter and 1 number (no special char or uppercase required)
const PASSWORD_REGEX = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

/**
 * Validate email format (BR-01)
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  return EMAIL_REGEX.test(email.trim());
}

/**
 * Validate phone format (BR-01)
 */
function isValidPhone(phone) {
  if (!phone || typeof phone !== 'string') return false;
  return PHONE_REGEX.test(phone.trim().replace(/[\s-]/g, ''));
}

/**
 * Validate password complexity per BR-02
 */
function isValidPassword(password) {
  if (!password || typeof password !== 'string') return false;
  return PASSWORD_REGEX.test(password);
}

/**
 * Validate bio length limit (BR-14: <= 150 characters)
 */
function isValidBio(bio) {
  if (bio === undefined || bio === null) return true;
  if (typeof bio !== 'string') return false;
  return bio.length <= 150;
}

/**
 * Validate user age >= 13 years old per BR-03
 * Avoids UTC timezone day shifts by directly parsing date components for strings.
 * @param {string|Date} birthday - YYYY-MM-DD
 */
function isAtLeast13YearsOld(birthday) {
  if (!birthday) return false;
  let bYear, bMonth, bDay;

  if (typeof birthday === 'string') {
    const parts = birthday.split('T')[0].split('-').map(Number);
    if (parts.length < 3 || parts.some(isNaN)) return false;
    [bYear, bMonth, bDay] = parts;
  } else if (birthday instanceof Date && !isNaN(birthday.getTime())) {
    bYear = birthday.getFullYear();
    bMonth = birthday.getMonth() + 1;
    bDay = birthday.getDate();
  } else {
    return false;
  }

  const today = new Date();
  let age = today.getFullYear() - bYear;
  const m = (today.getMonth() + 1) - bMonth;
  if (m < 0 || (m === 0 && today.getDate() < bDay)) {
    age--;
  }
  return age >= 13;
}

/**
 * Normalize gender string for PostgreSQL CHECK constraint
 */
function normalizeGender(gender) {
  if (!gender || typeof gender !== 'string') return 'other';
  const lower = gender.trim().toLowerCase();
  if (['male', 'female', 'other', 'custom'].includes(lower)) {
    return lower === 'custom' ? 'other' : lower;
  }
  return 'other';
}

/**
 * Validate post payload (BR-09)
 * Must have content OR media, content <= 5000 chars, media <= 10 items
 */
function validatePostPayload(content, mediaUrls) {
  const text = (content || '').trim();
  const media = Array.isArray(mediaUrls) ? mediaUrls : [];

  if (text.length === 0 && media.length === 0) {
    return { valid: false, message: 'Post must contain either text content or media' };
  }
  if (text.length > 5000) {
    return { valid: false, message: 'Post content cannot exceed 5000 characters' };
  }
  if (media.length > 10) {
    return { valid: false, message: 'Post cannot contain more than 10 media items' };
  }
  return { valid: true };
}

/**
 * Validate reaction type (BR-12)
 */
const VALID_REACTION_TYPES = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];
function isValidReactionType(type) {
  return VALID_REACTION_TYPES.includes(type);
}

/**
 * Validate comment content (BR-13)
 * 1-1000 characters
 */
function validateCommentPayload(content) {
  if (!content || typeof content !== 'string') {
    return { valid: false, message: 'Comment content is required' };
  }
  const text = content.trim();
  if (text.length === 0) {
    return { valid: false, message: 'Comment content cannot be empty' };
  }
  if (text.length > 1000) {
    return { valid: false, message: 'Comment content cannot exceed 1000 characters' };
  }
  return { valid: true, text };
}

/**
 * Validate profile update fields (BR-14)
 */
function validateProfilePayload(payload) {
  if (payload.bio !== undefined && payload.bio !== null) {
    if (typeof payload.bio !== 'string' || payload.bio.length > 150) {
      return { valid: false, message: 'Bio cannot exceed 150 characters' };
    }
  }
  if (payload.full_name !== undefined) {
    if (typeof payload.full_name !== 'string' || payload.full_name.trim().length === 0) {
      return { valid: false, message: 'Full name cannot be empty' };
    }
    if (payload.full_name.trim().length > 100) {
      return { valid: false, message: 'Full name cannot exceed 100 characters' };
    }
  }
  if (payload.city !== undefined && payload.city !== null && payload.city.length > 100) {
    return { valid: false, message: 'City cannot exceed 100 characters' };
  }
  if (payload.workplace !== undefined && payload.workplace !== null && payload.workplace.length > 100) {
    return { valid: false, message: 'Workplace cannot exceed 100 characters' };
  }
  return { valid: true };
}

module.exports = {
  PASSWORD_REGEX,
  isValidEmail,
  isValidPhone,
  isValidPassword,
  isValidBio,
  isAtLeast13YearsOld,
  normalizeGender,
  validatePostPayload,
  isValidReactionType,
  VALID_REACTION_TYPES,
  validateCommentPayload,
  validateProfilePayload,
};
