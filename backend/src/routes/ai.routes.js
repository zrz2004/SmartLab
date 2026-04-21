import express from 'express';

import { createId, labs as memoryLabs } from '../data/store.js';
import { requireAuth } from '../middleware/auth.js';
import { alertRepository } from '../repositories/alert.repository.js';
import { inspectionRepository } from '../repositories/inspection.repository.js';
import { mediaRepository } from '../repositories/media.repository.js';
import { inspectImageWithSiliconFlow } from '../services/siliconflow.service.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

function buildFallbackInspection(body) {
  const riskMatrix = {
    door: ['warning', 0.84, 'Door appears not fully secured.'],
    window: ['warning', 0.81, 'Window appears open and needs manual confirmation.'],
    water: ['warning', 0.78, 'Water source appears active or wet area is visible.'],
    power: ['warning', 0.8, 'Power switch or socket state needs manual confirmation.'],
    oven: ['critical', 0.86, 'Oven power or surrounding area may be unsafe.'],
    device: ['info', 0.7, 'Device scene archived for manual review.'],
    chemical: ['warning', 0.77, 'Chemical storage scene needs manual validation.'],
    alert: ['warning', 0.74, 'Alert evidence uploaded and queued for manual review.']
  };

  const [riskLevel, confidence, reason] = riskMatrix[body.sceneType] ?? ['warning', 0.72, 'Scene archived and waiting for manual review.'];

  return {
    sceneType: body.sceneType ?? 'general',
    deviceType: body.deviceType ?? 'unknown',
    riskLevel,
    confidence,
    reason,
    recommendedAction: 'Notify staff and require manual confirmation before closing the incident.',
    evidence: ['server-fallback-rule'],
    labId: body.labId,
    capturedAt: new Date().toISOString(),
    reviewStatus: 'pending_review',
    model: body.preferredModel ?? 'Qwen/Qwen3-VL-32B-Instruct'
  };
}

function normalizeInspectionPayload(raw, body) {
  if (!raw || typeof raw !== 'object') {
    return buildFallbackInspection(body);
  }

  return {
    sceneType: raw.sceneType ?? body.sceneType ?? 'general',
    deviceType: raw.deviceType ?? body.deviceType ?? 'unknown',
    riskLevel: raw.riskLevel ?? 'warning',
    confidence: Number(raw.confidence ?? 0.75),
    reason: raw.reason ?? 'Manual review required.',
    recommendedAction: raw.recommendedAction ?? 'Ask staff to confirm safety state.',
    evidence: Array.isArray(raw.evidence) ? raw.evidence : ['siliconflow-response'],
    labId: raw.labId ?? body.labId ?? '',
    capturedAt: raw.capturedAt ?? new Date().toISOString(),
    reviewStatus: raw.reviewStatus ?? 'pending_review',
    model: raw.model ?? body.preferredModel ?? 'Qwen/Qwen3-VL-32B-Instruct'
  };
}

router.post('/', requireAuth, asyncHandler(async (req, res) => {
  const mediaRecord = mediaRepository.getById(req.body.mediaRecordId);

  let normalized = buildFallbackInspection(req.body);
  try {
    const siliconFlowResponse = await inspectImageWithSiliconFlow({
      imageUrl: req.body.mediaUrl ?? mediaRecord?.url,
      prompt: `Lab=${req.body.labId}; scene=${req.body.sceneType}; device=${req.body.deviceType}; return structured safety inspection JSON.`
    });
    const content = siliconFlowResponse?.choices?.[0]?.message?.content;
    const parsed = typeof content === 'string' ? JSON.parse(content) : content;
    normalized = normalizeInspectionPayload(parsed, req.body);
  } catch (_) {
    normalized = buildFallbackInspection(req.body);
  }

  const inspection = await inspectionRepository.create({
    id: createId('inspect'),
    ...normalized,
    mediaUrl: req.body.mediaUrl ?? mediaRecord?.url ?? null,
    mediaRecordId: req.body.mediaRecordId ?? null,
    targetId: req.body.targetId ?? null,
    rawResponse: normalized
  });

  const lab = memoryLabs.find((item) => item.id === inspection.labId);
  await alertRepository.createAiAlert({
    id: createId('alert_ai'),
    type: inspection.sceneType === 'window'
        ? 'windowOpen'
        : inspection.sceneType === 'door'
            ? 'doorUnlocked'
            : inspection.sceneType === 'water'
                ? 'waterLeak'
                : inspection.sceneType === 'power' || inspection.sceneType === 'oven'
                    ? 'powerOverload'
                    : 'other',
    level: inspection.riskLevel === 'critical' ? 'critical' : inspection.riskLevel === 'info' ? 'info' : 'warning',
    title: 'AI inspection warning',
    message: inspection.reason,
    device_id: inspection.targetId ?? 'ai_camera',
    device_name: 'AI image inspection',
    room_id: lab?.roomNumber ?? '',
    building_id: lab?.buildingId ?? '',
    lab_id: inspection.labId,
    timestamp: inspection.capturedAt,
    snapshot: {
      source: 'ai',
      model: inspection.model_primary ?? inspection.model,
      confidence: inspection.confidence,
      reviewStatus: inspection.review_status ?? inspection.reviewStatus,
      mediaUrl: inspection.media_url ?? inspection.mediaUrl
    },
    inspection_id: inspection.id,
    confidence: inspection.confidence,
    evidence: inspection.evidence ?? [],
    review_status: inspection.review_status ?? inspection.reviewStatus
  });

  res.status(202).json({
    id: inspection.id,
    sceneType: inspection.scene_type ?? inspection.sceneType,
    deviceType: inspection.device_type ?? inspection.deviceType,
    riskLevel: inspection.risk_level ?? inspection.riskLevel,
    confidence: Number(inspection.confidence),
    reason: inspection.reason,
    recommendedAction: inspection.recommended_action ?? inspection.recommendedAction,
    evidence: inspection.evidence,
    labId: inspection.lab_id ?? inspection.labId,
    capturedAt: inspection.created_at ?? inspection.capturedAt,
    reviewStatus: inspection.review_status ?? inspection.reviewStatus,
    model: inspection.model_primary ?? inspection.model,
    mediaUrl: inspection.media_url ?? inspection.mediaUrl
  });
}));

router.get('/:id', requireAuth, asyncHandler(async (req, res) => {
  const inspection = await inspectionRepository.getById(req.params.id);
  if (!inspection) {
    return res.status(404).json({ message: 'AI inspection not found.' });
  }
  return res.json(inspection);
}));

export default router;
