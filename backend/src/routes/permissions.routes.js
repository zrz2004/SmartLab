import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { userRepository } from '../repositories/user.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/me', requireAuth, asyncHandler(async (req, res) => {
  const permissions = await userRepository.getPermissionsForUser(req.user);
  res.json(permissions.map((code) => ({ code, role: req.user.role })));
}));

export default router;
