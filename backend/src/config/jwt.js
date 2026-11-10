// Single source of the JWT secret. No built-in default: a known secret would let anyone forge tokens.
const LEAKED_DEFAULT = 'super_secret_fb_clone_course_project_jwt_key_2026_prm393';

function jwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    throw new Error('JWT_SECRET is missing or shorter than 32 characters. Set a long random value in backend/.env.');
  }
  if (secret === LEAKED_DEFAULT && process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET is still the public example value. Generate a new one for production.');
  }
  return secret;
}

module.exports = { jwtSecret };
