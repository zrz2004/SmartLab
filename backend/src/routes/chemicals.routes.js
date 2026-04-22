import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { chemicalRepository } from '../repositories/chemical.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

router.get('/inventory', requireAuth, asyncHandler(async (req, res) => {
  res.json(await chemicalRepository.listInventory(req.user));
}));

router.get('/cabinets', requireAuth, asyncHandler(async (req, res) => {
  res.json(await chemicalRepository.listCabinets(req.user));
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

router.get('/inventory/:id/responsibilities', requireAuth, asyncHandler(async (req, res) => {
  res.json(await chemicalRepository.getResponsibilities(req.params.id));
}));

router.post('/inventory', requireAuth, asyncHandler(async (req, res) => {
  const created = await chemicalRepository.createChemical({
    payload: req.body,
    operator: req.user
  });
  res.status(201).json(created);
}));

router.put('/inventory/:id', requireAuth, asyncHandler(async (req, res) => {
  const updated = await chemicalRepository.updateChemical({
    chemicalId: req.params.id,
    payload: req.body,
    operator: req.user
  });
  if (!updated) {
    return res.status(404).json({ message: 'Chemical not found.' });
  }
  res.json(updated);
}));

router.put('/inventory/:id/responsibilities', requireAuth, asyncHandler(async (req, res) => {
  const userIds = Array.isArray(req.body.user_ids) ? req.body.user_ids : [];
  res.json(await chemicalRepository.replaceResponsibilities({
    chemicalId: req.params.id,
    userIds,
    assignedBy: req.user?.id ?? null
  }));
}));

router.delete('/inventory/:id', requireAuth, asyncHandler(async (req, res) => {
  const deleted = await chemicalRepository.deleteChemical(req.params.id);
  if (!deleted) {
    return res.status(404).json({ message: 'Chemical not found.' });
  }
  res.status(204).send();
}));

router.post('/inventory/:id/check-in', requireAuth, asyncHandler(async (req, res) => {
  const quantity = Number(req.body.quantity ?? 0);
  if (!Number.isFinite(quantity) || quantity <= 0) {
    return res.status(400).json({ message: 'quantity must be greater than 0.' });
  }
  const result = await chemicalRepository.adjustStock({
    chemicalId: req.params.id,
    action: 'checkIn',
    quantity,
    notes: req.body.notes ?? '',
    operator: req.user
  });
  if (!result) {
    return res.status(404).json({ message: 'Chemical not found.' });
  }
  res.json(result);
}));

router.post('/inventory/:id/check-out', requireAuth, asyncHandler(async (req, res) => {
  const quantity = Number(req.body.quantity ?? 0);
  if (!Number.isFinite(quantity) || quantity <= 0) {
    return res.status(400).json({ message: 'quantity must be greater than 0.' });
  }
  const result = await chemicalRepository.adjustStock({
    chemicalId: req.params.id,
    action: 'checkOut',
    quantity,
    notes: req.body.notes ?? '',
    operator: req.user
  });
  if (!result) {
    return res.status(404).json({ message: 'Chemical not found.' });
  }
  res.json(result);
}));

export default router;
