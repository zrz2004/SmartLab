import { getUserByAccessToken } from '../data/store.js';
import { userRepository } from '../repositories/user.repository.js';

function extractToken(req) {
  const header = req.headers.authorization ?? '';
  if (!header.startsWith('Bearer ')) return null;
  return header.slice(7).trim();
}

export function requireAuth(req, res, next) {
  (async () => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ message: 'Missing bearer token.' });
    }

    const session = getUserByAccessToken(token);
    if (!session) {
      return res.status(401).json({ message: 'Invalid or expired access token.' });
    }

    const user = await userRepository.findById(session.userId);
    if (!user) {
      return res.status(401).json({ message: 'User not found for current session.' });
    }

    req.authToken = token;
    req.user = user;
    return next();
  })().catch((error) => {
    return res.status(500).json({ message: error.message });
  });
}

export function requireRole(roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required.' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient role.' });
    }
    return next();
  };
}

export function requirePermission(permission) {
  return (req, res, next) => {
    (async () => {
      if (!req.user) {
        return res.status(401).json({ message: 'Authentication required.' });
      }
      const permissions = await userRepository.getPermissionsForUser(req.user);
      if (!permissions.includes(permission)) {
        return res.status(403).json({ message: `Missing permission: ${permission}` });
      }
      return next();
    })().catch((error) => {
      return res.status(500).json({ message: error.message });
    });
  };
}
