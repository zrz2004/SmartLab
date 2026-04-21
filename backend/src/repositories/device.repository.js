import { devices as memoryDevices, labs as memoryLabs } from '../data/store.js';
import { isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { getSupportedLegacyLabIds, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

function mapSensorTypeToDeviceType(sensorType) {
  switch (sensorType) {
    case 'temperature':
    case 'humidity':
    case 'voc':
    case 'smoke':
      return 'environmentSensor';
    case 'current':
      return 'powerMonitor';
    case 'water_leak':
      return 'waterSensor';
    default:
      return 'environmentSensor';
  }
}

function buildLegacyTelemetry(sensorType, value) {
  const numericValue = value == null ? null : Number(value);
  switch (sensorType) {
    case 'temperature':
      return { temperature: numericValue };
    case 'humidity':
      return { humidity: numericValue };
    case 'voc':
      return { voc: numericValue };
    case 'current':
      return { power: numericValue, leakageCurrent: numericValue };
    case 'water_leak':
      return { waterLeak: numericValue };
    case 'smoke':
      return { smoke: numericValue };
    default:
      return { value: numericValue };
  }
}

class DeviceRepository {
  async list({ user, roomId, type }) {
    if (!isDatabaseConfigured()) {
      return memoryDevices.filter((device) => {
        const matchesLab = !roomId || device.lab_id === roomId || device.position === roomId;
        const matchesType = !type || device.type === type;
        const canAccess = user.role === 'admin' || user.accessibleLabIds.includes(device.lab_id);
        return matchesLab && matchesType && canAccess;
      });
    }

    if (await isLegacySchema()) {
      const supportedLabIds = getSupportedLegacyLabIds();
      const requestedLabId = toDatabaseLabId(roomId);
      const accessibleLabIds = user.role === 'admin'
          ? supportedLabIds
          : user.accessibleLabIds.map((item) => toDatabaseLabId(item)).filter(Boolean);

      if (accessibleLabIds.length === 0) {
        return [];
      }

      const result = await query(
        `
        select
          s.id::text as id,
          s.name,
          s.type as sensor_type,
          s.lab_id,
          s.location,
          s.status,
          l.name as lab_name
        from sensors s
        join labs l on l.id = s.lab_id
        where ($1::int is null or s.lab_id = $1)
          and ($2::boolean = true or s.lab_id = any($3::int[]))
        order by s.id
        `,
        [requestedLabId, user.role === 'admin', accessibleLabIds]
      );

      return result.rows
          .map((row) => ({
            id: row.id,
            name: row.name,
            type: mapSensorTypeToDeviceType(row.sensor_type),
            lab_id: toExternalLabId(row.lab_id),
            position: row.location,
            status: row.status,
            metadata: {
              sensorType: row.sensor_type,
              labName: row.lab_name
            }
          }))
          .filter((item) => !type || item.type === type);
    }

    const result = await query(
      `
      select *
      from devices
      where ($1::text is null or lab_id = $1 or room_id = $1)
        and ($2::text is null or type = $2)
        and ($3::boolean = true or lab_id in (
          select lab_id from user_lab_access where user_id = $4
        ))
      order by id
      `,
      [roomId ?? null, type ?? null, user.role === 'admin', user.id]
    );
    return result.rows;
  }

  async getDetail(deviceId) {
    if (!isDatabaseConfigured()) {
      const device = memoryDevices.find((item) => item.id === deviceId);
      if (!device) return null;
      const lab = memoryLabs.find((item) => item.id === device.lab_id);
      return {
        ...device,
        lab_name: lab?.name ?? '',
        firmware_version: 'v2.1.3',
        protocol: 'MQTT / HTTP',
        telemetry: {
          temperature: device.type === 'environmentSensor' ? 24.2 : null,
          humidity: device.type === 'environmentSensor' ? 46.5 : null
        }
      };
    }

    if (await isLegacySchema()) {
      const result = await query(
        `
        select
          s.id::text as id,
          s.name,
          s.type as sensor_type,
          s.lab_id,
          s.location,
          s.status,
          l.name as lab_name,
          coalesce((
            select sr.value
            from sensor_readings sr
            where sr.sensor_id = s.id
            order by sr.timestamp desc
            limit 1
          ), null) as latest_value
        from sensors s
        join labs l on l.id = s.lab_id
        where s.id = $1
        limit 1
        `,
        [Number(deviceId)]
      );
      if (result.rowCount === 0) return null;
      const row = result.rows[0];
      return {
        id: row.id,
        name: row.name,
        type: mapSensorTypeToDeviceType(row.sensor_type),
        lab_id: toExternalLabId(row.lab_id),
        position: row.location,
        status: row.status,
        lab_name: row.lab_name,
        firmware_version: 'legacy-db',
        protocol: 'HTTP / PostgreSQL',
        telemetry: buildLegacyTelemetry(row.sensor_type, row.latest_value),
        metadata: {
          sensorType: row.sensor_type
        }
      };
    }

    const result = await query(
      `
      select d.*, l.name as lab_name
      from devices d
      left join labs l on l.id = d.lab_id
      where d.id = $1
      limit 1
      `,
      [deviceId]
    );
    if (result.rowCount === 0) return null;
    return result.rows[0];
  }

  async getTelemetryHistory({ deviceId, start, end, interval = '1h' }) {
    const device = await this.getDetail(deviceId);
    if (!device) {
      return [];
    }

    if (await isLegacySchema()) {
      const sensorType = device.metadata?.sensorType ?? 'temperature';
      const queryStart = Number.isFinite(start) ? new Date(start * 1000) : new Date(Date.now() - 24 * 60 * 60 * 1000);
      const queryEnd = Number.isFinite(end) ? new Date(end * 1000) : new Date();
      const result = await query(
        `
        select value, timestamp
        from sensor_readings
        where sensor_id = $1
          and timestamp between $2 and $3
        order by timestamp asc
        `,
        [Number(deviceId), queryStart.toISOString(), queryEnd.toISOString()]
      );

      if (result.rowCount > 0) {
        return result.rows.map((row) => ({
          timestamp: row.timestamp,
          deviceId,
          values: buildLegacyTelemetry(sensorType, row.value)
        }));
      }
    }

    const startTime = Number.isFinite(start) ? new Date(start * 1000) : new Date(Date.now() - 24 * 60 * 60 * 1000);
    const endTime = Number.isFinite(end) ? new Date(end * 1000) : new Date();
    const bucketCount = Math.max(6, Math.min(48, interval === '15m' ? 32 : 24));
    const spanMs = Math.max(1, endTime.getTime() - startTime.getTime());
    const stepMs = Math.floor(spanMs / bucketCount);
    const telemetry = device.telemetry ?? {};
    const baseTemperature = Number(telemetry.temperature ?? 23.5);
    const baseHumidity = Number(telemetry.humidity ?? 45);
    const basePower = Number(telemetry.power ?? 1600);
    const baseLeakage = Number(telemetry.leakageCurrent ?? telemetry.leakage_current ?? 5);

    return Array.from({ length: bucketCount }, (_, index) => {
      const sampledAt = new Date(startTime.getTime() + stepMs * index);
      const wave = Math.sin(index / 3);
      return {
        timestamp: sampledAt.toISOString(),
        deviceId,
        values: {
          temperature: Number((baseTemperature + wave * 1.2).toFixed(1)),
          humidity: Number((baseHumidity + wave * 4).toFixed(1)),
          power: Number((basePower + wave * 90).toFixed(0)),
          leakageCurrent: Number((baseLeakage + wave * 0.8).toFixed(1))
        }
      };
    });
  }

  async getLatestTelemetry(deviceId) {
    const device = await this.getDetail(deviceId);
    if (!device) {
      return null;
    }

    if (await isLegacySchema()) {
      return {
        timestamp: new Date().toISOString(),
        deviceId,
        values: device.telemetry ?? {}
      };
    }

    return {
      timestamp: new Date().toISOString(),
      deviceId,
      values: device.telemetry ?? {}
    };
  }

  async controlDevice({ deviceId, action }) {
    if (!isDatabaseConfigured()) {
      const device = memoryDevices.find((item) => item.id === deviceId);
      if (!device) return null;

      const normalizedAction = String(action).toUpperCase();
      device.status = normalizedAction === 'OFF' || normalizedAction === 'CLOSE' || normalizedAction === 'LOCK'
          ? 'standby'
          : 'online';
      device.last_command = normalizedAction;
      device.last_command_at = new Date().toISOString();
      return device;
    }

    const device = await this.getDetail(deviceId);
    if (!device) {
      return null;
    }

    const normalizedAction = String(action).toUpperCase();
    const status = normalizedAction === 'OFF' || normalizedAction === 'CLOSE' || normalizedAction === 'LOCK'
        ? 'standby'
        : 'online';

    if (await isLegacySchema()) {
      const result = await query(
        `
        update sensors
        set status = $2
        where id = $1
        returning id::text as id, status
        `,
        [Number(deviceId), status]
      );
      return result.rows[0] ?? null;
    }

    const result = await query(
      `
      update devices
      set status = $2,
          updated_at = now(),
          telemetry = telemetry || $3::jsonb
      where id = $1
      returning *
      `,
      [
        deviceId,
        status,
        JSON.stringify({
          lastCommand: normalizedAction,
          lastCommandAt: new Date().toISOString()
        })
      ]
    );
    return result.rows[0] ?? null;
  }
}

export const deviceRepository = new DeviceRepository();
