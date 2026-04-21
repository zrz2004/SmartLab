import crypto from 'crypto';
import bcrypt from 'bcryptjs';

function sha256(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

export function hashPassword(password) {
  return bcrypt.hashSync(password, 10);
}

export function comparePassword(password, hash) {
  if (typeof hash !== 'string' || hash.length === 0) {
    return false;
  }

  if (hash.startsWith('$2a$') || hash.startsWith('$2b$') || hash.startsWith('$2y$')) {
    return bcrypt.compareSync(password, hash);
  }

  return sha256(password) === hash;
}
