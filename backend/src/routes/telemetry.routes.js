import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { deviceRepository } from '../repositories/device.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/history', requireAuth, asyncHandler(async (req, res) => {
  const deviceId = String(req.query.deviceId ?? '');
  if (!deviceId) {
    return res.status(400).json({ message: 'deviceId is required.' });
  }

  const start = Number(req.query.start);
  const end = Number(req.query.end);
  const interval = String(req.query.interval ?? '1h');
  const history = await deviceRepository.getTelemetryHistory({
    deviceId,
    start,
    end,
    interval
  });
  return res.json(history);
}));

router.get('/latest', requireAuth, asyncHandler(async (req, res) => {
  const deviceId = String(req.query.deviceId ?? '');
  if (!deviceId) {
    return res.status(400).json({ message: 'deviceId is required.' });
  }

  const latest = await deviceRepository.getLatestTelemetry(deviceId);
  if (!latest) {
    return res.status(404).json({ message: 'Device not found.' });
  }
  return res.json(latest);
}));

export default router;
