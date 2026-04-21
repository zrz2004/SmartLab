import { alerts as memoryAlerts } from '../data/store.js';
import { isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

class AlertRepository {
  async list({ level, acknowledged, limit = 50 }) {
    if (!isDatabaseConfigured()) {
      return memoryAlerts
          .filter((item) => {
            const matchesLevel = !level || item.level === level;
            const matchesAck = acknowledged === undefined ? true : String(item.is_acknowledged) === String(acknowledged);
            return matchesLevel && matchesAck;
          })
          .slice(0, limit);
    }

    if (await isLegacySchema()) {
      const result = await query(
        `
        select
          a.id::text as id,
          a.sensor_id::text as device_id,
          s.name as device_name,
          a.lab_id,
          a.type,
          a.severity,
          a.title,
          a.description,
          a.status,
          a.acknowledged_at,
          a.acknowledged_by,
          a.created_at
        from alerts a
        left join sensors s on s.id = a.sensor_id
        where ($1::text is null or a.severity = $1)
          and (
            $2::boolean is null
            or ($2 = true and a.status = 'acknowledged')
            or ($2 = false and a.status <> 'acknowledged')
          )
        order by a.created_at desc
        limit $3
        `,
        [level ?? null, acknowledged ?? null, limit]
      );

      return result.rows.map((row) => ({
        id: row.id,
        type: row.type,
        level: row.severity,
        title: row.title,
        message: row.description,
        device_id: row.device_id,
        device_name: row.device_name ?? 'Legacy sensor',
        lab_id: toExternalLabId(row.lab_id),
        timestamp: row.created_at,
        is_acknowledged: row.status === 'acknowledged',
        acknowledged_at: row.acknowledged_at,
        acknowledged_by: row.acknowledged_by?.toString() ?? null,
        source: 'sensor',
        review_status: row.status === 'acknowledged' ? 'reviewed' : 'pending_review'
      }));
    }

    const result = await query(
      `
      select *
      from alerts
      where ($1::text is null or level = $1)
        and ($2::boolean is null or is_acknowledged = $2)
      order by timestamp desc
      limit $3
      `,
      [level ?? null, acknowledged ?? null, limit]
    );
    return result.rows;
  }

  async acknowledge(alertId, operator) {
    if (!isDatabaseConfigured()) {
      const alert = memoryAlerts.find((item) => item.id === alertId);
      if (!alert) return null;
      alert.is_acknowledged = true;
      alert.acknowledged_at = new Date().toISOString();
      alert.acknowledged_by = operator?.name ?? operator;
      return alert;
    }

    if (await isLegacySchema()) {
      const result = await query(
        `
        update alerts
        set status = 'acknowledged',
            acknowledged_at = now(),
            acknowledged_by = $2
        where id = $1
        returning id::text as id, acknowledged_at, acknowledged_by
        `,
        [Number(alertId), Number(operator?.id ?? null)]
      );
      return result.rows[0] ?? null;
    }

    const result = await query(
      `
      update alerts
      set is_acknowledged = true,
          acknowledged_at = now(),
          acknowledged_by = $2
      where id = $1
      returning *
      `,
      [alertId, operator?.name ?? operator]
    );
    return result.rows[0] ?? null;
  }

  async createAiAlert(payload) {
    if (!isDatabaseConfigured()) {
      const next = {
        source: 'ai',
        ...payload
      };
      memoryAlerts.unshift(next);
      return next;
    }

    if (await isLegacySchema()) {
      const result = await query(
        `
        insert into alerts (
          sensor_id, lab_id, type, severity, title, description, status, created_at
        )
        values ($1, $2, $3, $4, $5, $6, 'pending', now())
        returning id::text as id, created_at
        `,
        [
          null,
          toDatabaseLabId(payload.lab_id),
          payload.type,
          payload.level,
          payload.title,
          payload.message
        ]
      );
      return {
        id: result.rows[0].id,
        type: payload.type,
        level: payload.level,
        title: payload.title,
        message: payload.message,
        device_id: payload.device_id,
        device_name: payload.device_name,
        lab_id: payload.lab_id,
        timestamp: result.rows[0].created_at,
        source: 'ai',
        confidence: payload.confidence ?? null,
        evidence: payload.evidence ?? [],
        review_status: payload.review_status ?? 'pending_review'
      };
    }

    const result = await query(
      `
      insert into alerts (
        id, type, level, title, message, device_id, device_name,
        room_id, building_id, lab_id, timestamp, snapshot, source,
        inspection_id, confidence, evidence, review_status, is_acknowledged
      )
      values (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12::jsonb, 'ai',
        $13, $14, $15::jsonb, $16, false
      )
      returning *
      `,
      [
        payload.id,
        payload.type,
        payload.level,
        payload.title,
        payload.message,
        payload.device_id,
        payload.device_name,
        payload.room_id,
        payload.building_id,
        payload.lab_id,
        payload.timestamp,
        JSON.stringify(payload.snapshot ?? {}),
        payload.inspection_id ?? null,
        payload.confidence ?? null,
        JSON.stringify(payload.evidence ?? []),
        payload.review_status ?? 'pending_review'
      ]
    );
    return result.rows[0];
  }
}

export const alertRepository = new AlertRepository();
