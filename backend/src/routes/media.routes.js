import express from 'express';
import multer from 'multer';

import { createId } from '../data/store.js';
import { requireAuth } from '../middleware/auth.js';
import { mediaRepository } from '../repositories/media.repository.js';
import { createInspectionMediaRecord, uploadToNocoDb } from '../services/nocodb.service.js';
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
  let upstreamRecordId = null;
  let upstreamPath = null;
  let upstreamSignedPath = null;

  try {
    const uploaded = await uploadToNocoDb({
      buffer: req.file.buffer,
      fileName: req.file.originalname
    });
    upstreamUrl = uploaded?.url ?? uploaded?.path ?? null;
    upstreamProvider = 'nocodb';
    upstreamPath = uploaded?.path ?? null;
    upstreamSignedPath = uploaded?.signedPath ?? null;
    const record = await createInspectionMediaRecord({
      labId: req.body.lab_id,
      sceneType: req.body.scene_type,
      deviceType: req.body.device_type,
      targetId: req.body.target_id ?? null,
      provider: upstreamProvider,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      attachment: uploaded?.raw ?? [],
      storagePath: upstreamPath,
      signedPath: upstreamSignedPath,
      capturedAt: new Date().toISOString()
    });
    upstreamRecordId = record?.Id ?? record?.id ?? null;
  } catch (_) {
    upstreamUrl = null;
  }

  const localUrl = `${req.protocol}://${req.get('host')}/api/v1/media/${recordId}`;
  const record = await mediaRepository.create({
    id: recordId,
    fileName: req.file.originalname,
    mimeType: req.file.mimetype,
    size: req.file.size,
    buffer: req.file.buffer,
    metadata: {
      labId: req.body.lab_id,
      sceneType: req.body.scene_type,
      deviceType: req.body.device_type,
      targetId: req.body.target_id ?? null,
      nocodbRecordId: upstreamRecordId,
      nocodbPath: upstreamPath,
      nocodbSignedPath: upstreamSignedPath
    },
    url: upstreamUrl ?? localUrl,
    provider: upstreamProvider,
    createdAt: new Date().toISOString(),
    createdBy: req.user?.id ?? null
  });

  return res.status(201).json({
    recordId: record.id,
    url: record.url,
    fileName: record.fileName,
    metadata: record.metadata,
    provider: record.provider,
    persisted: record.persisted ?? false,
    nocodbRecordId: upstreamRecordId
  });
}));

router.get('/:id', requireAuth, asyncHandler(async (req, res) => {
  const record = await mediaRepository.getById(req.params.id);
  if (!record) {
    return res.status(404).json({ message: 'Media not found.' });
  }
  if (!record.buffer) {
    return res.redirect(record.url);
  }
  res.setHeader('Content-Type', record.mimeType);
  res.send(record.buffer);
}));

export default router;
