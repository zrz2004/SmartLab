import express from 'express';
import multer from 'multer';

import { createId } from '../data/store.js';
import { requireAuth } from '../middleware/auth.js';
import { mediaRepository } from '../repositories/media.repository.js';
import { uploadToNocoDb } from '../services/nocodb.service.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/upload', requireAuth, upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'file is required.' });
  }

  const recordId = createId('media');
  let upstreamUrl = null;
  let upstreamProvider = 'local';

  try {
    const uploaded = await uploadToNocoDb({
      buffer: req.file.buffer,
      fileName: req.file.originalname
    });
    upstreamUrl = uploaded?.url ?? uploaded?.path ?? null;
    upstreamProvider = 'nocodb';
  } catch (_) {
    upstreamUrl = null;
  }

  const localUrl = `${req.protocol}://${req.get('host')}/api/v1/media/${recordId}`;
  const record = mediaRepository.create({
    id: recordId,
    fileName: req.file.originalname,
    mimeType: req.file.mimetype,
    size: req.file.size,
    buffer: req.file.buffer,
    metadata: {
      labId: req.body.lab_id,
      sceneType: req.body.scene_type,
      deviceType: req.body.device_type,
      targetId: req.body.target_id ?? null
    },
    url: upstreamUrl ?? localUrl,
    provider: upstreamProvider,
    createdAt: new Date().toISOString()
  });

  return res.status(202).json({
    recordId: record.id,
    url: record.url,
    fileName: record.fileName,
    metadata: record.metadata,
    provider: record.provider
  });
}));

router.get('/:id', requireAuth, (req, res) => {
  const record = mediaRepository.getById(req.params.id);
  if (!record) {
    return res.status(404).json({ message: 'Media not found.' });
  }
  res.setHeader('Content-Type', record.mimeType);
  res.send(record.buffer);
});

export default router;
