import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { deviceRepository } from '../repositories/device.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/', requireAuth, asyncHandler(async (req, res) => {
  const requestedLabId = req.query.roomId ?? req.query.labId ?? req.user.currentLabId ?? req.user.accessibleLabIds?.[0];
  const requestedType = req.query.type;
  const result = await deviceRepository.list({
    user: req.user,
    roomId: requestedLabId,
    type: requestedType
  });
  res.json(result);
}));

router.get('/:id', requireAuth, asyncHandler(async (req, res) => {
  const device = await deviceRepository.getDetail(req.params.id);
  if (!device) {
    return res.status(404).json({ message: 'Device not found.' });
  }
  return res.json(device);
}));

export default router;
