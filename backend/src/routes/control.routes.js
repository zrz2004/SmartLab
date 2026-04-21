import express from 'express';

import { requireAuth, requirePermission } from '../middleware/auth.js';
import { deviceRepository } from '../repositories/device.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.post('/switch', requireAuth, requirePermission('device.control'), asyncHandler(async (req, res) => {
  const deviceId = String(req.body.deviceId ?? '');
  const action = String(req.body.action ?? '');

  if (!deviceId || !action) {
    return res.status(400).json({ message: 'deviceId and action are required.' });
  }

  const device = await deviceRepository.controlDevice({
    deviceId,
    action
  });

  if (!device) {
    return res.status(404).json({ message: 'Device not found.' });
  }

  return res.json({
    id: device.id,
    status: device.status,
    action: String(action).toUpperCase(),
    executedAt: new Date().toISOString()
  });
}));

export default router;
