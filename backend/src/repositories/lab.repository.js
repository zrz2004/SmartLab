import { alerts as memoryAlerts, devices as memoryDevices, labs as memoryLabs } from '../data/store.js';
import { hasTable, isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { getSupportedLegacyLabIds, mapLegacyLabRow, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

function normalizeReminderTime(value, fallback) {
  const raw = String(value ?? fallback ?? '').trim();
  const match = raw.match(/^(\d{2}):(\d{2})/);
  if (!match) {
    return fallback;
  }
  return `${match[1]}:${match[2]}`;
}

class LabRepository {
  async getAllLabs() {
    if (!isDatabaseConfigured()) return memoryLabs;

    if (await isLegacySchema()) {
      const result = await query(
        `
        select l.*, b.name as building_name,
               count(s.id)::int as device_count
        from labs l
        left join buildings b on b.id = l.building_id
        left join sensors s on s.lab_id = l.id
        where l.id = any($1::int[])
        group by l.id, b.name
        order by l.id
        `,
        [getSupportedLegacyLabIds()]
      );
      return result.rows.map(mapLegacyLabRow);
    }

    const result = await query('select * from labs order by id');
    return result.rows;
  }

  async getAccessibleLabs(user) {
    if (!isDatabaseConfigured()) {
      return memoryLabs.filter((item) => user.role === 'admin' || user.accessibleLabIds.includes(item.id));
    }

    if (await isLegacySchema()) {
      const selectedLabIds = user.role === 'admin'
          ? getSupportedLegacyLabIds()
          : user.accessibleLabIds.map((item) => toDatabaseLabId(item)).filter(Boolean);
      if (selectedLabIds.length === 0) {
        return [];
      }

      const result = await query(
        `
        select l.*, b.name as building_name, count(s.id)::int as device_count
        from labs l
        left join buildings b on b.id = l.building_id
        left join sensors s on s.lab_id = l.id
        where l.id = any($1::int[])
        group by l.id, b.name
        order by l.id
        `,
        [selectedLabIds]
      );
      return result.rows.map(mapLegacyLabRow);
    }

    const result = await query(
      `
      select l.*
      from labs l
      join user_lab_access ula on ula.lab_id = l.id
      where ula.user_id = $1
      order by l.id
      `,
      [user.id]
    );
    return result.rows;
  }

  async getLabContext(labId) {
    if (!isDatabaseConfigured()) {
      const lab = memoryLabs.find((item) => item.id === labId);
      const labDevices = memoryDevices.filter((item) => item.lab_id === labId);
      if (!lab) return null;
      return {
        labId: lab.id,
        name: lab.name,
        mqttTopicPrefix: `lab/${lab.buildingId}/${lab.roomNumber}`,
        aiInspectionEnabled: true,
        availableDeviceTypes: [...new Set(labDevices.map((item) => item.type))]
      };
    }

    if (await isLegacySchema()) {
      const databaseLabId = toDatabaseLabId(labId);
      const labResult = await query(
        `
        select l.*, b.name as building_name
        from labs l
        left join buildings b on b.id = l.building_id
        where l.id = $1
        limit 1
        `,
        [databaseLabId]
      );
      if (labResult.rowCount === 0) return null;
      const lab = labResult.rows[0];
      const mappedLab = mapLegacyLabRow(lab);
      const deviceResult = await query('select distinct type from sensors where lab_id = $1 order by type', [databaseLabId]);
      return {
        labId: mappedLab.id,
        name: mappedLab.name,
        mqttTopicPrefix: `lab/${lab.building_id}/${mappedLab.room_number}`,
        aiInspectionEnabled: true,
        availableDeviceTypes: deviceResult.rows.map((row) => row.type)
      };
    }

    const labResult = await query('select * from labs where id = $1 limit 1', [labId]);
    if (labResult.rowCount === 0) return null;
    const lab = labResult.rows[0];
    const sourceTable = (await hasTable('devices')) ? 'devices' : 'sensors';
    const deviceResult = await query(`select distinct type from ${sourceTable} where lab_id = $1 order by type`, [labId]);
    return {
      labId: lab.id,
      name: lab.name,
      mqttTopicPrefix: `lab/${lab.building_id}/${lab.room_number}`,
      aiInspectionEnabled: true,
      availableDeviceTypes: deviceResult.rows.map((row) => row.type)
    };
  }

  async getSafetyScore(labId) {
    if (!isDatabaseConfigured()) {
      const roomId = labId === 'lab_yuanlou_806' ? '806' : '101';
      const labAlerts = memoryAlerts.filter((item) => item.room_id === roomId && !item.is_acknowledged);
      const score = Math.max(0, 100 - labAlerts.reduce((sum, item) => sum + (item.level === 'critical' ? 15 : item.level === 'warning' ? 5 : 1), 0));
      return { labId, score, alertCount: labAlerts.length };
    }

    if (await isLegacySchema()) {
      const databaseLabId = toDatabaseLabId(labId);
      const labResult = await query('select safety_score from labs where id = $1 limit 1', [databaseLabId]);
      const alertResult = await query(
        `
        select
          count(*) filter (where status <> 'acknowledged') as alert_count,
          coalesce(sum(
            case
              when status <> 'acknowledged' and severity = 'critical' then 15
              when status <> 'acknowledged' and severity = 'warning' then 5
              when status <> 'acknowledged' then 1
              else 0
            end
          ), 0) as deduction
        from alerts
        where lab_id = $1
        `,
        [databaseLabId]
      );
      const baseScore = Number(labResult.rows[0]?.safety_score ?? 100);
      const row = alertResult.rows[0] ?? {};
      return {
        labId: toExternalLabId(databaseLabId),
        score: Math.max(0, Math.min(100, Math.round(baseScore - Number(row.deduction ?? 0)))),
        alertCount: Number(row.alert_count ?? 0)
      };
    }

    const result = await query(
      `
      select
        count(*) filter (where not is_acknowledged) as alert_count,
        coalesce(sum(
          case
            when not is_acknowledged and level = 'critical' then 15
            when not is_acknowledged and level = 'warning' then 5
            when not is_acknowledged and level = 'info' then 1
            else 0
          end
        ), 0) as deduction
      from alerts
      where lab_id = $1
      `,
      [labId]
    );
    const row = result.rows[0];
    return {
      labId,
      score: Math.max(0, 100 - Number(row.deduction ?? 0)),
      alertCount: Number(row.alert_count ?? 0)
    };
  }

  async getReminderSettings(labId) {
    if (!isDatabaseConfigured()) {
      return {
        labId,
        enabled: true,
        firstReminderTime: '19:00',
        secondReminderTime: '23:00',
        updatedAt: null,
        updatedBy: null
      };
    }

    if (!(await hasTable('lab_upload_reminder_settings'))) {
      return {
        labId,
        enabled: true,
        firstReminderTime: '19:00',
        secondReminderTime: '23:00',
        updatedAt: null,
        updatedBy: null
      };
    }

    if (await isLegacySchema()) {
      const databaseLabId = toDatabaseLabId(labId);
      const result = await query(
        `
        select
          l.id as lab_id,
          s.enabled,
          s.first_reminder_time::text as first_reminder_time,
          s.second_reminder_time::text as second_reminder_time,
          s.updated_at,
          s.updated_by
        from labs l
        left join lab_upload_reminder_settings s on s.lab_id = l.id
        where l.id = $1
        limit 1
        `,
        [databaseLabId]
      );
      if (result.rowCount === 0) {
        return null;
      }
      const row = result.rows[0];
      return {
        labId: toExternalLabId(row.lab_id),
        enabled: row.enabled ?? true,
        firstReminderTime: normalizeReminderTime(row.first_reminder_time, '19:00'),
        secondReminderTime: normalizeReminderTime(row.second_reminder_time, '23:00'),
        updatedAt: row.updated_at ?? null,
        updatedBy: row.updated_by != null ? String(row.updated_by) : null
      };
    }

    const result = await query(
      `
      select
        l.id as lab_id,
        s.enabled,
        s.first_reminder_time::text as first_reminder_time,
        s.second_reminder_time::text as second_reminder_time,
        s.updated_at,
        s.updated_by
      from labs l
      left join lab_upload_reminder_settings s on s.lab_id = l.id
      where l.id = $1
      limit 1
      `,
      [labId]
    );
    if (result.rowCount === 0) {
      return null;
    }
    const row = result.rows[0];
    return {
      labId: row.lab_id,
      enabled: row.enabled ?? true,
      firstReminderTime: normalizeReminderTime(row.first_reminder_time, '19:00'),
      secondReminderTime: normalizeReminderTime(row.second_reminder_time, '23:00'),
      updatedAt: row.updated_at ?? null,
      updatedBy: row.updated_by != null ? String(row.updated_by) : null
    };
  }

  async upsertReminderSettings({
    labId,
    enabled,
    firstReminderTime,
    secondReminderTime,
    updatedBy
  }) {
    if (!isDatabaseConfigured()) {
      return {
        labId,
        enabled,
        firstReminderTime,
        secondReminderTime,
        updatedAt: new Date().toISOString(),
        updatedBy: updatedBy != null ? String(updatedBy) : null
      };
    }

    if (!(await hasTable('lab_upload_reminder_settings'))) {
      throw new Error('lab_upload_reminder_settings table is missing.');
    }

    if (await isLegacySchema()) {
      const databaseLabId = toDatabaseLabId(labId);
      const result = await query(
        `
        insert into lab_upload_reminder_settings (
          lab_id,
          enabled,
          first_reminder_time,
          second_reminder_time,
          updated_by,
          updated_at
        )
        values ($1, $2, $3::time, $4::time, $5, now())
        on conflict (lab_id) do update
        set enabled = excluded.enabled,
            first_reminder_time = excluded.first_reminder_time,
            second_reminder_time = excluded.second_reminder_time,
            updated_by = excluded.updated_by,
            updated_at = now()
        returning
          lab_id,
          enabled,
          first_reminder_time::text as first_reminder_time,
          second_reminder_time::text as second_reminder_time,
          updated_at,
          updated_by
        `,
        [databaseLabId, enabled, firstReminderTime, secondReminderTime, updatedBy]
      );
      const row = result.rows[0];
      return {
        labId: toExternalLabId(row.lab_id),
        enabled: row.enabled,
        firstReminderTime: normalizeReminderTime(row.first_reminder_time, firstReminderTime),
        secondReminderTime: normalizeReminderTime(row.second_reminder_time, secondReminderTime),
        updatedAt: row.updated_at ?? null,
        updatedBy: row.updated_by != null ? String(row.updated_by) : null
      };
    }

    const result = await query(
      `
      insert into lab_upload_reminder_settings (
        lab_id,
        enabled,
        first_reminder_time,
        second_reminder_time,
        updated_by,
        updated_at
      )
      values ($1, $2, $3::time, $4::time, $5, now())
      on conflict (lab_id) do update
      set enabled = excluded.enabled,
          first_reminder_time = excluded.first_reminder_time,
          second_reminder_time = excluded.second_reminder_time,
          updated_by = excluded.updated_by,
          updated_at = now()
      returning
        lab_id,
        enabled,
        first_reminder_time::text as first_reminder_time,
        second_reminder_time::text as second_reminder_time,
        updated_at,
        updated_by
      `,
      [labId, enabled, firstReminderTime, secondReminderTime, updatedBy]
    );
    const row = result.rows[0];
    return {
      labId: row.lab_id,
      enabled: row.enabled,
      firstReminderTime: normalizeReminderTime(row.first_reminder_time, firstReminderTime),
      secondReminderTime: normalizeReminderTime(row.second_reminder_time, secondReminderTime),
      updatedAt: row.updated_at ?? null,
      updatedBy: row.updated_by != null ? String(row.updated_by) : null
    };
  }
}

export const labRepository = new LabRepository();
