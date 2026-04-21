import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { chemicalRepository } from '../repositories/chemical.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/inventory', requireAuth, asyncHandler(async (req, res) => {
  res.json(await chemicalRepository.listInventory(req.user));
}));

router.get('/inventory/:id', requireAuth, asyncHandler(async (req, res) => {
  const chemical = await chemicalRepository.getById(req.params.id);
  if (!chemical) {
    return res.status(404).json({ message: 'Chemical not found.' });
  }
  res.json(chemical);
}));

router.get('/inventory/logs', requireAuth, asyncHandler(async (req, res) => {
  const limit = Number(req.query.limit ?? 20);
  const chemicalId = req.query.chemicalId;
  res.json(await chemicalRepository.getLogs({ chemicalId, limit }));
}));

export default router;
