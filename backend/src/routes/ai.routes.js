import express from 'express';

import { createId, labs as memoryLabs } from '../data/store.js';
import { requireAuth } from '../middleware/auth.js';
import { alertRepository } from '../repositories/alert.repository.js';
import { inspectionRepository } from '../repositories/inspection.repository.js';
import { mediaRepository } from '../repositories/media.repository.js';
import {
  inspectImageWithSiliconFlow,
  rewriteInspectionTextToChinese
} from '../services/siliconflow.service.js';
import { asyncHandler } from '../utils/async-handler.js';

const router = express.Router();

function buildImageInput(mediaRecord, mediaUrl) {
  if (mediaRecord?.buffer) {
    const mimeType = mediaRecord.mimeType ?? 'image/jpeg';
    const encoded = Buffer.from(mediaRecord.buffer).toString('base64');
    return `data:${mimeType};base64,${encoded}`;
  }
  return mediaUrl ?? mediaRecord?.url ?? null;
}

function buildFallbackInspection(body) {
  const riskMatrix = {
    environment: ['info', 0.76, '等待后端结构化分析结果。'],
    door: ['warning', 0.84, '门体可能未上锁或未完全关闭。'],
    window: ['warning', 0.81, '窗户可能开启，需要人工确认。'],
    water: ['warning', 0.78, '水源可能未关闭或存在漏水迹象。'],
    power: ['warning', 0.80, '电源开关或插座状态需要人工进一步确认。'],
    oven: ['critical', 0.86, '烘箱电源状态或周边环境可能存在安全隐患。'],
    device: ['info', 0.70, '设备现场已归档，等待人工复核。'],
    chemical: ['warning', 0.77, '危化品柜现场需要人工进一步核验。'],
    alert: ['warning', 0.74, '报警补充取证已上传，等待人工复核。'],
    security: ['warning', 0.81, '门窗状态需要人工进一步确认。']
  };

  const [riskLevel, confidence, reason] =
    riskMatrix[body.sceneType] ?? ['warning', 0.72, '场景已归档，等待人工复核。'];

  return {
    sceneType: body.sceneType ?? 'general',
    deviceType: body.deviceType ?? 'unknown',
    riskLevel,
    confidence,
    reason,
    recommendedAction: '请安排值班人员现场复核并记录处理结果。',
    evidence: [
      'AI 服务未返回结构化结论，已启用兜底规则。',
      `场景类型：${body.sceneType ?? 'general'}`,
      `设备类型：${body.deviceType ?? 'unknown'}`
    ],
    labId: body.labId,
    capturedAt: new Date().toISOString(),
    reviewStatus: 'pending_review',
    model: body.preferredModel ?? 'Qwen/Qwen3-VL-32B-Instruct'
  };
}

function extractJsonPayload(content) {
  if (typeof content !== 'string') {
    return content;
  }

  const fencedMatch = content.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  const candidate = fencedMatch?.[1] ?? content;
  return JSON.parse(candidate);
}

function hasChineseText(value) {
  return /[\u4e00-\u9fff]/.test(String(value ?? ''));
}

async function ensureChineseDisplayFields(payload) {
  const reasonHasChinese = hasChineseText(payload.reason);
  const actionHasChinese = hasChineseText(payload.recommendedAction);
  const evidenceHasChinese = Array.isArray(payload.evidence)
    && payload.evidence.every((item) => hasChineseText(item));

  if (reasonHasChinese && actionHasChinese && evidenceHasChinese) {
    return payload;
  }

  try {
    const rewritten = await rewriteInspectionTextToChinese({
      reason: payload.reason,
      recommendedAction: payload.recommendedAction,
      evidence: payload.evidence
    });
    const rewrittenContent = rewritten?.choices?.[0]?.message?.content;
    const rewrittenPayload = extractJsonPayload(rewrittenContent);
    return {
      ...payload,
      reason: rewrittenPayload?.reason ?? payload.reason,
      recommendedAction:
        rewrittenPayload?.recommendedAction ?? payload.recommendedAction,
      evidence: Array.isArray(rewrittenPayload?.evidence)
        ? rewrittenPayload.evidence
        : payload.evidence
    };
  } catch (_) {
    return payload;
  }
}

function normalizeInspectionPayload(raw, body) {
  if (!raw || typeof raw !== 'object') {
    return buildFallbackInspection(body);
  }

  const normalizedRisk = String(raw.riskLevel ?? 'warning').toLowerCase();
  let canonicalRiskLevel = 'warning';
  if (['critical', 'high', 'danger', 'severe'].includes(normalizedRisk)) {
    canonicalRiskLevel = 'critical';
  } else if (['warning', 'warn', 'medium', 'moderate'].includes(normalizedRisk)) {
    canonicalRiskLevel = 'warning';
  } else if (['info', 'low', 'safe', 'normal', 'ok'].includes(normalizedRisk)) {
    canonicalRiskLevel = 'info';
  }

  return {
    sceneType: raw.sceneType ?? body.sceneType ?? 'general',
    deviceType: raw.deviceType ?? body.deviceType ?? 'unknown',
    riskLevel: canonicalRiskLevel,
    confidence: Number(raw.confidence ?? 0.75),
    reason: raw.reason ?? '需要人工进一步复核。',
    recommendedAction:
      raw.recommendedAction ?? '请安排值班人员现场复核并记录处理结果。',
    evidence: Array.isArray(raw.evidence) ? raw.evidence : ['siliconflow-response'],
    labId: raw.labId ?? body.labId ?? '',
    capturedAt: raw.capturedAt ?? new Date().toISOString(),
    reviewStatus: raw.reviewStatus ?? 'pending_review',
    model: raw.model ?? body.preferredModel ?? 'Qwen/Qwen3-VL-32B-Instruct'
  };
}

function serializeInspection(inspection) {
  if (!inspection) return null;
  return {
    id: inspection.id,
    sceneType: inspection.scene_type ?? inspection.sceneType,
    deviceType: inspection.device_type ?? inspection.deviceType,
    riskLevel: inspection.risk_level ?? inspection.riskLevel,
    confidence: Number(inspection.confidence ?? 0),
    reason: inspection.reason,
    recommendedAction: inspection.recommended_action ?? inspection.recommendedAction,
    evidence: inspection.evidence ?? [],
    labId: inspection.lab_id ?? inspection.labId,
    capturedAt: inspection.created_at ?? inspection.capturedAt,
    reviewStatus: inspection.review_status ?? inspection.reviewStatus,
    model: inspection.model_primary ?? inspection.model,
    mediaUrl: inspection.media_url ?? inspection.mediaUrl
  };
}

router.get('/latest', requireAuth, asyncHandler(async (req, res) => {
  const inspection = await inspectionRepository.getLatest({
    labId: req.query.labId ? String(req.query.labId) : null,
    sceneType: req.query.sceneType ? String(req.query.sceneType) : null,
    deviceType: req.query.deviceType ? String(req.query.deviceType) : null,
    targetId: req.query.targetId ? String(req.query.targetId) : null
  });
  if (!inspection) {
    return res.status(404).json({ message: 'AI inspection not found.' });
  }
  return res.json(serializeInspection(inspection));
}));

router.post('/', requireAuth, asyncHandler(async (req, res) => {
  const mediaRecord = req.body.mediaRecordId
    ? await mediaRepository.getById(req.body.mediaRecordId)
    : null;
  const imageInput = buildImageInput(mediaRecord, req.body.mediaUrl);

  let normalized = buildFallbackInspection(req.body);
  try {
    const siliconFlowResponse = await inspectImageWithSiliconFlow({
      imageUrl: imageInput,
      prompt: [
        `Lab=${req.body.labId}`,
        `Scene=${req.body.sceneType}`,
        `Device=${req.body.deviceType}`,
        '你是一名高校实验室安全巡检员，需要根据图片判断现场是否安全。',
        '仅返回 JSON，不要输出任何额外说明。',
        'sceneType 和 deviceType 保持英文枚举；riskLevel 只能是 critical、warning、info。',
        'reason、recommendedAction、evidence 必须使用简体中文，表达准确、具体、可执行。',
        'reason 必须直接描述图中可见风险，不得泛泛而谈。',
        'recommendedAction 必须给出值班人员下一步处置动作。',
        'evidence 必须包含 2 到 4 条简短的可视依据。',
        '若图中存在明火、燃气灶、可燃物靠近热源、插座疑似过载、门窗未关闭、水槽积水、阀门未关等情况，应提高风险等级。'
      ].join('; ')
    });
    const content = siliconFlowResponse?.choices?.[0]?.message?.content;
    const parsed = extractJsonPayload(content);
    normalized = normalizeInspectionPayload(parsed, req.body);
    normalized = await ensureChineseDisplayFields(normalized);
    normalized.model = siliconFlowResponse?.modelUsed ?? normalized.model;
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

  const inspectionView = serializeInspection(inspection);

  if (inspectionView?.riskLevel !== 'info') {
    const lab = memoryLabs.find((item) => item.id === inspectionView?.labId);
    await alertRepository.createAiAlert({
      id: createId('alert_ai'),
      type: inspectionView.sceneType === 'window'
        ? 'windowOpen'
        : inspectionView.sceneType === 'door'
            ? 'doorUnlocked'
            : inspectionView.sceneType === 'water'
                ? 'waterLeak'
                : inspectionView.sceneType === 'power' ||
                    inspectionView.sceneType === 'oven'
                    ? 'powerOverload'
                    : 'other',
      level: inspectionView.riskLevel == 'critical' ? 'critical' : 'warning',
      title: 'AI 图像预警',
      message: inspectionView.reason,
      device_id: inspection.targetId ?? 'ai_camera',
      device_name: 'AI 图像巡检',
      room_id: lab?.roomNumber ?? '',
      building_id: lab?.buildingId ?? '',
      lab_id: inspectionView.labId,
      timestamp: inspectionView.capturedAt,
      snapshot: {
        source: 'ai',
        model: inspectionView.model,
        confidence: inspectionView.confidence,
        reviewStatus: inspectionView.reviewStatus,
        mediaUrl: inspectionView.mediaUrl
      },
      inspection_id: inspectionView.id,
      confidence: inspectionView.confidence,
      evidence: inspectionView.evidence,
      review_status: inspectionView.reviewStatus
    });
  }

  res.status(202).json(inspectionView);
}));

router.get('/:id', requireAuth, asyncHandler(async (req, res) => {
  const inspection = await inspectionRepository.getById(req.params.id);
  if (!inspection) {
    return res.status(404).json({ message: 'AI inspection not found.' });
  }
  return res.json(serializeInspection(inspection));
}));

export default router;
