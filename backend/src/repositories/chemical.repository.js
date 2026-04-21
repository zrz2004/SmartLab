import { chemicalLogs as memoryLogs, chemicals as memoryChemicals } from '../data/store.js';
import { isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { getSupportedLegacyLabIds, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

class ChemicalRepository {
  async listInventory(user) {
    if (!isDatabaseConfigured()) {
      return memoryChemicals.filter((item) => user.role === 'admin' || user.accessibleLabIds.includes(item.lab_id));
    }

    if (await isLegacySchema()) {
      const accessibleLabIds = user.role === 'admin'
          ? getSupportedLegacyLabIds()
          : user.accessibleLabIds.map((item) => toDatabaseLabId(item)).filter(Boolean);
      if (accessibleLabIds.length === 0) {
        return [];
      }

      const result = await query(
        `
        select *
        from chemicals
        where lab_id = any($1::int[])
        order by id
        `,
        [accessibleLabIds]
      );
      return result.rows.map((row) => ({
        ...row,
        id: String(row.id),
        lab_id: toExternalLabId(row.lab_id)
      }));
    }

    const result = await query(
      `
      select *
      from chemicals
      where ($1::boolean = true or lab_id in (select lab_id from user_lab_access where user_id = $2))
      order by id
      `,
      [user.role === 'admin', user.id]
    );
    return result.rows;
  }

  async getById(chemicalId) {
    if (!isDatabaseConfigured()) {
      return memoryChemicals.find((item) => item.id === chemicalId) ?? null;
    }

    const result = await query('select * from chemicals where id = $1 limit 1', [Number(chemicalId)]);
    if (result.rowCount === 0) return null;
    return {
      ...result.rows[0],
      id: String(result.rows[0].id),
      lab_id: toExternalLabId(result.rows[0].lab_id)
    };
  }

  async getLogs({ chemicalId, limit = 20 }) {
    if (!isDatabaseConfigured()) {
      return memoryLogs.filter((item) => !chemicalId || item.chemical_id === chemicalId).slice(0, limit);
    }

    if (await isLegacySchema()) {
      const result = await query(
        `
        select *
        from chemical_logs
        where ($1::int is null or chemical_id = $1)
        order by timestamp desc
        limit $2
        `,
        [chemicalId ? Number(chemicalId) : null, limit]
      );
      return result.rows.map((row) => ({
        ...row,
        id: String(row.id),
        chemical_id: String(row.chemical_id)
      }));
    }

    const result = await query(
      `
      select *
      from chemical_logs
      where ($1::text is null or chemical_id = $1)
      order by timestamp desc
      limit $2
      `,
      [chemicalId ?? null, limit]
    );
    return result.rows;
  }
}

export const chemicalRepository = new ChemicalRepository();
