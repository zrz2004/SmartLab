import express from 'express';

import { getUserByRefreshToken, issueTokens, revokeAccessToken, revokeRefreshToken } from '../data/store.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { userRepository } from '../repositories/user.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.post('/register', asyncHandler(async (req, res) => {
  try {
    const { username, password, name, email, phone, requested_role: requestedRole = 'undergraduate' } = req.body;

    if (!username || !password || !name || !email) {
      return res.status(400).json({ message: 'username, password, name, and email are required.' });
    }

    const existing = await userRepository.findByUsername(username);
    if (existing) {
      return res.status(409).json({ message: 'Username already exists.' });
    }

    const created = await userRepository.createRegistrationRequest({
      username,
      password,
      name,
      email,
      phone,
      requestedRole
    });

    return res.status(202).json(created);
  } catch (error) {
    return res.status(409).json({ message: error.message });
  }
}));

router.post('/login', asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  const authResult = await userRepository.authenticate(username, password);

  if (!authResult) {
    return res.status(401).json({ message: 'Invalid username or password.' });
  }

  const accessibleLabs = await userRepository.getAccessibleLabs(authResult.user);
  const permissions = await userRepository.getPermissionsForUser(authResult.user);

  return res.json({
    access_token: authResult.accessToken,
    refresh_token: authResult.refreshToken,
    user: userRepository.sanitizeUser(authResult.user),
    permissions,
    accessible_labs: accessibleLabs
  });
}));

router.post('/logout', requireAuth, (req, res) => {
  revokeAccessToken(req.authToken);
  return res.status(204).send();
});

router.post('/refresh', asyncHandler(async (req, res) => {
  const refreshToken = req.body.refresh_token;
  if (!refreshToken) {
    return res.status(400).json({ message: 'refresh_token is required.' });
  }

  const session = getUserByRefreshToken(refreshToken);
  if (!session) {
    return res.status(401).json({ message: 'Invalid refresh token.' });
  }

  revokeRefreshToken(refreshToken);
  const tokens = issueTokens(session.userId);

  return res.json({
    access_token: tokens.accessToken,
    refresh_token: tokens.refreshToken
  });
}));

router.get('/me', requireAuth, (req, res) => {
  res.json(userRepository.sanitizeUser(req.user));
});

router.get('/pending', requireAuth, requireRole(['admin', 'teacher']), asyncHandler(async (_req, res) => {
  res.json(await userRepository.listPendingRegistrations());
}));

router.post('/pending/:id/approve', requireAuth, requireRole(['admin', 'teacher']), asyncHandler(async (req, res) => {
  const assignedLabs = Array.isArray(req.body.lab_ids) && req.body.lab_ids.length > 0 ? req.body.lab_ids : ['lab_yuanlou_806'];
  const assignedRole = req.body.role ?? 'undergraduate';

  const approvedUser = await userRepository.approveRegistration(req.params.id, assignedRole, assignedLabs);
  if (!approvedUser) {
    return res.status(404).json({ message: 'Registration request not found.' });
  }

  return res.json({
    id: req.params.id,
    status: 'approved',
    role: assignedRole,
    lab_ids: assignedLabs,
    user: userRepository.sanitizeUser(approvedUser)
  });
}));

router.post('/pending/:id/reject', requireAuth, requireRole(['admin', 'teacher']), asyncHandler(async (req, res) => {
  const ok = await userRepository.rejectRegistration(req.params.id, req.body.reason ?? '');
  if (!ok) {
    return res.status(404).json({ message: 'Registration request not found.' });
  }

  return res.json({
    id: req.params.id,
    status: 'rejected',
    reason: req.body.reason ?? ''
  });
}));

export default router;
