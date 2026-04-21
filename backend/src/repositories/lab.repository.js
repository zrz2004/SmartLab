import { alerts as memoryAlerts, devices as memoryDevices, labs as memoryLabs } from '../data/store.js';
import { hasTable, isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { getSupportedLegacyLabIds, mapLegacyLabRow, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

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
      const deviceResult = await query('select distinct type from sensors where lab_id = $1 order by type', [databaseLabId]);
      return {
        labId: toExternalLabId(lab.id),
        name: lab.name,
        mqttTopicPrefix: `lab/${lab.building_id}/${lab.room_number}`,
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
}

export const labRepository = new LabRepository();
