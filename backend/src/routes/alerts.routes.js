import express from 'express';

import { requireAuth, requirePermission } from '../middleware/auth.js';
import { alertRepository } from '../repositories/alert.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/', requireAuth, asyncHandler(async (req, res) => {
  const limit = Number(req.query.limit ?? 50);
  const acknowledged = req.query.acknowledged === undefined ? undefined : String(req.query.acknowledged) === 'true';
  const level = req.query.level;
  const labId = req.query.labId ? String(req.query.labId) : undefined;
  const result = await alertRepository.list({ level, acknowledged, labId, limit });
  res.json(result);
}));

router.post('/:id/acknowledge', requireAuth, requirePermission('alert.acknowledge'), asyncHandler(async (req, res) => {
  const alert = await alertRepository.acknowledge(req.params.id, req.user);
  if (!alert) {
    return res.status(404).json({ message: 'Alert not found.' });
  }

  res.json({
    id: alert.id,
    acknowledged: true,
    acknowledgedAt: alert.acknowledged_at,
    acknowledgedBy: alert.acknowledged_by
  });
}));

export default router;
