import express from 'express';

import { requireAuth } from '../middleware/auth.js';
import { labRepository } from '../repositories/lab.repository.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

function canAccessLab(accessibleLabs, labId) {
  return accessibleLabs.some((lab) => lab.id === labId);
}

function isValidReminderTime(value) {
  return /^([01]\d|2[0-3]):([0-5]\d)$/.test(String(value ?? '').trim());
}

router.get('/', requireAuth, asyncHandler(async (_req, res) => res.json(await labRepository.getAllLabs())));

router.get('/accessible', requireAuth, asyncHandler(async (req, res) => {
  res.json(await labRepository.getAccessibleLabs(req.user));
}));

router.post('/select', requireAuth, asyncHandler(async (req, res) => {
  const labId = req.body.lab_id;
  const accessibleLabs = await labRepository.getAccessibleLabs(req.user);
  const canAccess = canAccessLab(accessibleLabs, labId);

  if (!labId || !canAccess) {
    return res.status(403).json({ message: 'Lab is not accessible for current user.' });
  }

  req.user.currentLabId = labId;
  return res.json({
    currentLabId: labId,
    switchedAt: new Date().toISOString()
  });
}));

router.get('/:id/reminder-settings', requireAuth, asyncHandler(async (req, res) => {
  const accessibleLabs = await labRepository.getAccessibleLabs(req.user);
  if (req.user.role !== 'admin' && !canAccessLab(accessibleLabs, req.params.id)) {
    return res.status(403).json({ message: 'Lab is not accessible for current user.' });
  }

  const settings = await labRepository.getReminderSettings(req.params.id);
  if (!settings) {
    return res.status(404).json({ message: 'Lab not found.' });
  }
  return res.json(settings);
}));

router.put('/:id/reminder-settings', requireAuth, asyncHandler(async (req, res) => {
  if (!['admin', 'teacher'].includes(req.user.role)) {
    return res.status(403).json({ message: 'Only admins and teachers can update reminder settings.' });
  }

  const accessibleLabs = await labRepository.getAccessibleLabs(req.user);
  if (req.user.role !== 'admin' && !canAccessLab(accessibleLabs, req.params.id)) {
    return res.status(403).json({ message: 'Lab is not accessible for current user.' });
  }

  const enabled = req.body.enabled !== false;
  const firstReminderTime = String(req.body.first_reminder_time ?? '').trim();
  const secondReminderTime = String(req.body.second_reminder_time ?? '').trim();

  if (!isValidReminderTime(firstReminderTime) || !isValidReminderTime(secondReminderTime)) {
    return res.status(400).json({ message: 'Reminder time must use HH:MM format.' });
  }

  if (firstReminderTime === secondReminderTime) {
    return res.status(400).json({ message: 'Reminder times must be different.' });
  }

  const settings = await labRepository.upsertReminderSettings({
    labId: req.params.id,
    enabled,
    firstReminderTime,
    secondReminderTime,
    updatedBy: req.user.id
  });

  return res.json(settings);
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
