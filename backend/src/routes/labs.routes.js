import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { labRepository } from '../repositories/lab.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/', requireAuth, asyncHandler(async (_req, res) => res.json(await labRepository.getAllLabs())));

router.get('/accessible', requireAuth, asyncHandler(async (req, res) => {
  res.json(await labRepository.getAccessibleLabs(req.user));
}));

router.post('/select', requireAuth, asyncHandler(async (req, res) => {
  const labId = req.body.lab_id;
  const accessibleLabs = await labRepository.getAccessibleLabs(req.user);
  const canAccess = accessibleLabs.some((lab) => lab.id === labId);

  if (!labId || !canAccess) {
    return res.status(403).json({ message: 'Lab is not accessible for current user.' });
  }

  req.user.currentLabId = labId;
  return res.json({
    currentLabId: labId,
    switchedAt: new Date().toISOString()
  });
}));

router.get('/:id/context', requireAuth, asyncHandler(async (req, res) => {
  const context = await labRepository.getLabContext(req.params.id);
  if (!context) {
    return res.status(404).json({ message: 'Lab not found.' });
  }
  return res.json(context);
}));

router.get('/:id/safety-score', requireAuth, asyncHandler(async (req, res) => {
  res.json(await labRepository.getSafetyScore(req.params.id));
}));

export default router;
