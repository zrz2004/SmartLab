import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { userRepository } from '../repositories/user.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/', requireAuth, asyncHandler(async (req, res) => {
  const labId = req.query.labId ? String(req.query.labId) : undefined;
  res.json(await userRepository.listLabMembers({ requester: req.user, labId }));
}));

router.put('/:id', requireAuth, asyncHandler(async (req, res) => {
  const updated = await userRepository.updateUserProfile({
    requester: req.user,
    userId: req.params.id,
    payload: {
      name: req.body.name,
      phone: req.body.phone,
      email: req.body.email,
      department: req.body.department,
      role: req.body.role
    }
  });
  if (!updated) {
    return res.status(404).json({ message: 'User not found.' });
  }
  return res.json(updated);
}));

export default router;
