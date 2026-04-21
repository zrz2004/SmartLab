import { aiInspections as memoryInspections } from '../data/store.js';
import { isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

class InspectionRepository {
  async create(inspection) {
    if (!isDatabaseConfigured()) {
      memoryInspections.unshift(inspection);
      return inspection;
    }

    const result = await query(
      `
      insert into inspection_records (
        id, lab_id, scene_type, device_type, target_id, risk_level, confidence,
        reason, recommended_action, evidence, review_status, model_primary,
        model_fallback, model_compat, media_record_id, media_url, raw_response
      )
      values (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10::jsonb, $11, $12,
        $13, $14, $15, $16, $17::jsonb
      )
      returning *
      `,
      [
        inspection.id,
        (await isLegacySchema()) ? toDatabaseLabId(inspection.labId) : inspection.labId,
        inspection.sceneType,
        inspection.deviceType,
        inspection.targetId ?? null,
        inspection.riskLevel,
        inspection.confidence,
        inspection.reason,
        inspection.recommendedAction,
        JSON.stringify(inspection.evidence ?? []),
        inspection.reviewStatus,
        inspection.model,
        inspection.modelFallback ?? null,
        inspection.modelCompat ?? null,
        inspection.mediaRecordId ?? null,
        inspection.mediaUrl ?? null,
        JSON.stringify(inspection.rawResponse ?? {})
      ]
    );
    return result.rows[0];
  }

  async getById(id) {
    if (!isDatabaseConfigured()) {
      return memoryInspections.find((item) => item.id === id) ?? null;
    }
    const result = await query('select * from inspection_records where id = $1 limit 1', [id]);
    if (result.rowCount === 0) return null;
    if (await isLegacySchema()) {
      return {
        ...result.rows[0],
        lab_id: toExternalLabId(result.rows[0].lab_id)
      };
    }
    return result.rows[0];
  }
}

export const inspectionRepository = new InspectionRepository();
