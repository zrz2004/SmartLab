import { chemicalLogs as memoryLogs, chemicals as memoryChemicals } from '../data/store.js';
import { hasColumn, hasTable, isDatabaseConfigured, isLegacySchema, query, withClient } from '../db.js';
import { getSupportedLegacyLabIds, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';

class ChemicalRepository {
  async _resolveLegacyUserId(value) {
    if (value == null) {
      return null;
    }

    const normalized = String(value).trim();
    if (!normalized) {
      return null;
    }

    const numericId = Number(normalized);
    if (Number.isInteger(numericId)) {
      return numericId;
    }

    const aliasRoleMap = new Map([
      ['staff_admin', 'admin'],
      ['staff_teacher', 'teacher'],
      ['staff_manager', 'admin']
    ]);
    const aliasUsernameMap = new Map([
      ['staff_admin', 'admin'],
      ['staff_teacher', 'teacher'],
      ['staff_manager', 'admin']
    ]);
    const requestedRole = aliasRoleMap.get(normalized);
    if (requestedRole) {
      const hasProfileTable = await hasTable('user_profiles');
      const hasNameColumn = await hasColumn('users', 'name');
      const hasRoleColumn = await hasColumn('users', 'role');
      const result = await query(
        `
        select u.id
        from users u
        ${hasProfileTable ? 'left join user_profiles up on up.user_id = u.id' : ''}
        where ${hasRoleColumn ? "coalesce(u.role, 'undergraduate')" : "'undergraduate'"} = $1
        order by ${hasProfileTable ? 'coalesce(up.name, ' : ''}${hasNameColumn ? 'u.name, ' : ''}u.username${hasProfileTable ? ')' : ''}
        limit 1
        `,
        [requestedRole]
      );
      if (result.rowCount > 0) {
        return Number(result.rows[0].id);
      }
    }

    const requestedUsername = aliasUsernameMap.get(normalized) ?? normalized;
    const byUsername = await query(
      'select id from users where username = $1 limit 1',
      [requestedUsername]
    );
    if (byUsername.rowCount > 0) {
      return Number(byUsername.rows[0].id);
    }

    return null;
  }

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
      const hasChemicalMetadata = await hasTable('chemical_metadata');

      const result = await query(
        `
        select
          c.*,
          ${hasChemicalMetadata ? 'cm.shelf_code,' : "'' as shelf_code,"}
          ${hasChemicalMetadata ? 'cm.rfid_tag,' : 'null as rfid_tag,'}
          ${hasChemicalMetadata ? 'cm.notes' : 'null as notes'}
        from chemicals c
        ${hasChemicalMetadata ? 'left join chemical_metadata cm on cm.chemical_id = c.id' : ''}
        where c.lab_id = any($1::int[])
        order by id
        `,
        [accessibleLabIds]
      );
      const responsibilities = await this._getLegacyResponsibilitiesMap();
      return result.rows.map((row) => ({
        ...row,
        id: String(row.id),
        lab_id: toExternalLabId(row.lab_id),
        responsible_users: responsibilities.get(String(row.id)) ?? []
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
    const rows = result.rows;
    if (!(await hasTable('chemical_responsibilities'))) {
      return rows;
    }
    const responsibilityResult = await query(
      `
      select cr.chemical_id, u.id::text as user_id, coalesce(u.name, u.username) as name, coalesce(u.role, 'undergraduate') as role
      from chemical_responsibilities cr
      join users u on u.id = cr.user_id
      where cr.chemical_id = any($1::text[])
      order by cr.assigned_at asc
      `,
      [rows.map((row) => row.id)]
    );
    const responsibilityMap = new Map();
    for (const row of responsibilityResult.rows) {
      const key = String(row.chemical_id);
      const current = responsibilityMap.get(key) ?? [];
      current.push({
        id: row.user_id,
        name: row.name,
        role: row.role
      });
      responsibilityMap.set(key, current);
    }
    return rows.map((row) => ({
      ...row,
      responsible_users: responsibilityMap.get(String(row.id)) ?? []
    }));
  }

  async getById(chemicalId) {
    if (!isDatabaseConfigured()) {
      return memoryChemicals.find((item) => item.id === chemicalId) ?? null;
    }

    const legacySchema = await isLegacySchema();
    const hasChemicalMetadata = legacySchema ? await hasTable('chemical_metadata') : false;
    const result = await query(
      legacySchema
          ? `
            select
              c.*,
              ${hasChemicalMetadata ? 'cm.shelf_code,' : "'' as shelf_code,"}
              ${hasChemicalMetadata ? 'cm.rfid_tag,' : 'null as rfid_tag,'}
              ${hasChemicalMetadata ? 'cm.notes' : 'null as notes'}
            from chemicals c
            ${hasChemicalMetadata ? 'left join chemical_metadata cm on cm.chemical_id = c.id' : ''}
            where c.id = $1
            limit 1
            `
          : 'select * from chemicals where id = $1 limit 1',
      [legacySchema ? Number(chemicalId) : chemicalId]
    );
    if (result.rowCount === 0) return null;
    const payload = {
      ...result.rows[0],
      id: String(result.rows[0].id),
      lab_id: toExternalLabId(result.rows[0].lab_id)
    };
    const responsibilities = await this.getResponsibilities(chemicalId);
    return {
      ...payload,
      responsible_users: responsibilities
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
        id: String(row.id),
        chemical_id: String(row.chemical_id),
        action: row.action === 'checkIn' || row.action === 'checkOut' ? row.action : 'audit',
        quantity: Number(row.quantity_change ?? 0),
        performed_by: row.user_id != null ? `user_${row.user_id}` : 'system',
        timestamp: row.timestamp ?? row.created_at,
        notes: row.notes ?? row.description ?? ''
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

  async listCabinets(user) {
    const inventory = await this.listInventory(user);
    const grouped = new Map();
    for (const item of inventory) {
      const key = item.cabinet_id ?? item.cabinetId;
      if (!key) continue;
      const current = grouped.get(key) ?? {
        cabinet_id: key,
        lab_id: item.lab_id ?? item.labId,
        hazard_classes: new Set(),
        item_count: 0
      };
      current.hazard_classes.add(item.hazard_class ?? item.hazardClass);
      current.item_count += 1;
      grouped.set(key, current);
    }
    return [...grouped.values()].map((item) => ({
      cabinet_id: item.cabinet_id,
      lab_id: item.lab_id,
      hazard_classes: [...item.hazard_classes],
      item_count: item.item_count
    }));
  }

  async getResponsibilities(chemicalId) {
    if (!isDatabaseConfigured() || !(await hasTable('chemical_responsibilities'))) {
      return [];
    }

    const hasNameColumn = await hasColumn('users', 'name');
    const hasRoleColumn = await hasColumn('users', 'role');
    const hasEmailColumn = await hasColumn('users', 'email');
    const hasPhoneColumn = await hasColumn('users', 'phone');
    const normalizedChemicalId = await isLegacySchema() ? Number(chemicalId) : chemicalId;
    const result = await query(
      `
      select cr.id, cr.responsibility_type, cr.notes, cr.assigned_at,
             u.id::text as user_id,
             ${hasNameColumn ? 'coalesce(u.name, u.username)' : 'u.username'} as name,
             ${hasRoleColumn ? "coalesce(u.role, 'undergraduate')" : "'undergraduate'"} as role,
             ${hasEmailColumn ? 'u.email' : 'null'} as email,
             ${hasPhoneColumn ? 'u.phone' : 'null'} as phone
      from chemical_responsibilities cr
      join users u on u.id = cr.user_id
      where cr.chemical_id = $1
      order by cr.assigned_at asc
      `,
      [normalizedChemicalId]
    );

    return result.rows.map((row) => ({
      id: row.user_id,
      name: row.name,
      role: row.role,
      email: row.email,
      phone: row.phone,
      responsibilityType: row.responsibility_type,
      notes: row.notes,
      assignedAt: row.assigned_at
    }));
  }

  async adjustStock({ chemicalId, action, quantity, notes, operator }) {
    if (!isDatabaseConfigured()) {
      const target = memoryChemicals.find((item) => String(item.id) === String(chemicalId));
      if (!target) return null;
      target.quantity = Math.max(0, Number(target.quantity) + (action === 'checkIn' ? quantity : -quantity));
      target.status = target.quantity <= 0 ? 'checkedOut' : 'inStock';
      const log = {
        id: `log_${Date.now()}`,
        chemical_id: String(chemicalId),
        action,
        quantity,
        performed_by: operator?.name ?? operator?.username ?? 'system',
        timestamp: new Date().toISOString(),
        notes: notes ?? ''
      };
      memoryLogs.unshift(log);
      return {
        chemical: target,
        log
      };
    }

    if (await isLegacySchema()) {
      const normalizedChemicalId = Number(chemicalId);
      const current = await query('select * from chemicals where id = $1 limit 1', [normalizedChemicalId]);
      if (current.rowCount === 0) {
        return null;
      }
      const row = current.rows[0];
      const nextQuantity = Math.max(0, Number(row.quantity ?? 0) + (action === 'checkIn' ? quantity : -quantity));
      const nextStatus = nextQuantity <= 0 ? 'checkedOut' : 'inStock';
      const updated = await query(
        `
        update chemicals
        set quantity = $2,
            status = $3
        where id = $1
        returning *
        `,
        [normalizedChemicalId, nextQuantity, nextStatus]
      );
      const hasNotesColumn = await hasColumn('chemical_logs', 'notes');
      const hasTimestampColumn = await hasColumn('chemical_logs', 'timestamp');
      const log = await query(
        `
        insert into chemical_logs (
          chemical_id,
          user_id,
          action,
          quantity_change,
          description,
          ${hasTimestampColumn ? 'timestamp' : 'created_at'}
          ${hasNotesColumn ? ', notes' : ''}
        )
        values (
          $1,
          $2,
          $3,
          $4,
          $5,
          now()
          ${hasNotesColumn ? ', $6' : ''}
        )
        returning *
        `,
        hasNotesColumn
            ? [
                normalizedChemicalId,
                operator?.id != null ? Number.parseInt(String(operator.id), 10) : null,
                action,
                action === 'checkIn' ? quantity : -quantity,
                notes ?? '',
                notes ?? ''
              ]
            : [
                normalizedChemicalId,
                operator?.id != null ? Number.parseInt(String(operator.id), 10) : null,
                action,
                action === 'checkIn' ? quantity : -quantity,
                notes ?? ''
              ]
      );
      return {
        chemical: {
          ...updated.rows[0],
          id: String(updated.rows[0].id),
          lab_id: toExternalLabId(updated.rows[0].lab_id),
          responsible_users: await this.getResponsibilities(chemicalId)
        },
        log: {
          id: String(log.rows[0].id),
          chemical_id: String(log.rows[0].chemical_id),
          action: log.rows[0].action,
          quantity: Math.abs(Number(log.rows[0].quantity_change ?? 0)),
          performed_by: log.rows[0].user_id != null ? `user_${log.rows[0].user_id}` : 'system',
          timestamp: log.rows[0].timestamp ?? log.rows[0].created_at,
          notes: log.rows[0].notes ?? log.rows[0].description ?? ''
        }
      };
    }

    return null;
  }

  async createChemical({ payload, operator }) {
    if (!isDatabaseConfigured()) {
      const record = {
        id: `chem_${Date.now()}`,
        lab_id: payload.lab_id,
        name: payload.name,
        cas_number: payload.cas_number ?? '',
        cabinet_id: payload.cabinet_id ?? '',
        shelf_code: payload.shelf_code ?? '',
        hazard_class: payload.hazard_class ?? 'other',
        status: payload.status ?? 'inStock',
        quantity: Number(payload.quantity ?? 0),
        unit: payload.unit ?? 'bottle',
        expiry_date: payload.expiry_date ?? new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(),
        rfid_tag: payload.rfid_tag ?? null,
        notes: payload.notes ?? null,
        responsible_users: []
      };
      memoryChemicals.unshift(record);
      if (Array.isArray(payload.responsible_user_ids) && payload.responsible_user_ids.length > 0) {
        record.responsible_users = payload.responsible_user_ids.map((id) => ({
          id: String(id),
          name: `user_${id}`,
          role: 'teacher',
          responsibility_type: 'custodian'
        }));
      }
      return record;
    }

    const isLegacy = await isLegacySchema();
    const normalizedLabId = isLegacy ? toDatabaseLabId(payload.lab_id) : payload.lab_id;
    const hasNotesColumn = await hasColumn('chemicals', 'notes');
    const hasRfidColumn = await hasColumn('chemicals', 'rfid_tag');
    const hasShelfCodeColumn = await hasColumn('chemicals', 'shelf_code');
    const hasChemicalMetadata = isLegacy ? await hasTable('chemical_metadata') : false;
    const insertColumns = [
      'lab_id', 'name', 'cas_number', 'cabinet_id',
      'hazard_class', 'status', 'quantity', 'unit', 'expiry_date'
    ];
    const values = [
      normalizedLabId,
      payload.name,
      payload.cas_number ?? '',
      payload.cabinet_id ?? '',
      payload.hazard_class ?? 'other',
      payload.status ?? 'inStock',
      Number(payload.quantity ?? 0),
      payload.unit ?? 'bottle',
      payload.expiry_date ?? new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString()
    ];
    if (hasShelfCodeColumn) {
      insertColumns.push('shelf_code');
      values.push(payload.shelf_code ?? '');
    }
    if (hasRfidColumn) {
      insertColumns.push('rfid_tag');
      values.push(payload.rfid_tag ?? null);
    }
    if (hasNotesColumn) {
      insertColumns.push('notes');
      values.push(payload.notes ?? null);
    }
    const placeholders = values.map((_, index) => `$${index + 1}`);
    const result = await query(
      `insert into chemicals (${insertColumns.join(', ')}) values (${placeholders.join(', ')}) returning *`,
      values
    );
    const chemical = result.rows[0];
    if (isLegacy && hasChemicalMetadata) {
      await query(
        `
        insert into chemical_metadata (chemical_id, shelf_code, rfid_tag, notes, updated_at)
        values ($1, $2, $3, $4, now())
        on conflict (chemical_id) do update
        set shelf_code = excluded.shelf_code,
            rfid_tag = excluded.rfid_tag,
            notes = excluded.notes,
            updated_at = now()
        `,
        [chemical.id, payload.shelf_code ?? '', payload.rfid_tag ?? null, payload.notes ?? null]
      );
    }
    if (Array.isArray(payload.responsible_user_ids)) {
      await this.replaceResponsibilities({
        chemicalId: chemical.id,
        userIds: payload.responsible_user_ids,
        assignedBy: operator?.id ?? null
      });
    }
    return this.getById(chemical.id);
  }

  async updateChemical({ chemicalId, payload, operator }) {
    if (!isDatabaseConfigured()) {
      const target = memoryChemicals.find((item) => String(item.id) === String(chemicalId));
      if (!target) return null;
      Object.assign(target, {
        lab_id: payload.lab_id ?? target.lab_id,
        name: payload.name ?? target.name,
        cas_number: payload.cas_number ?? target.cas_number,
        cabinet_id: payload.cabinet_id ?? target.cabinet_id,
        shelf_code: payload.shelf_code ?? target.shelf_code,
        hazard_class: payload.hazard_class ?? target.hazard_class,
        status: payload.status ?? target.status,
        quantity: payload.quantity ?? target.quantity,
        unit: payload.unit ?? target.unit,
        expiry_date: payload.expiry_date ?? target.expiry_date,
        rfid_tag: payload.rfid_tag ?? target.rfid_tag,
        notes: payload.notes ?? target.notes
      });
      if (Array.isArray(payload.responsible_user_ids)) {
        target.responsible_users = payload.responsible_user_ids.map((id) => ({
          id: String(id),
          name: `user_${id}`,
          role: 'teacher',
          responsibility_type: 'custodian'
        }));
      }
      return target;
    }

    const isLegacy = await isLegacySchema();
    const hasNotesColumn = await hasColumn('chemicals', 'notes');
    const hasRfidColumn = await hasColumn('chemicals', 'rfid_tag');
    const hasShelfCodeColumn = await hasColumn('chemicals', 'shelf_code');
    const hasChemicalMetadata = isLegacy ? await hasTable('chemical_metadata') : false;
    const updates = [];
    const values = [];
    let index = 2;

    const assign = (field, value) => {
      updates.push(`${field} = $${index++}`);
      values.push(value);
    };

    if (payload.lab_id !== undefined) assign('lab_id', isLegacy ? toDatabaseLabId(payload.lab_id) : payload.lab_id);
    if (payload.name !== undefined) assign('name', payload.name);
    if (payload.cas_number !== undefined) assign('cas_number', payload.cas_number);
    if (payload.cabinet_id !== undefined) assign('cabinet_id', payload.cabinet_id);
    if (payload.shelf_code !== undefined && hasShelfCodeColumn) assign('shelf_code', payload.shelf_code);
    if (payload.hazard_class !== undefined) assign('hazard_class', payload.hazard_class);
    if (payload.status !== undefined) assign('status', payload.status);
    if (payload.quantity !== undefined) assign('quantity', Number(payload.quantity));
    if (payload.unit !== undefined) assign('unit', payload.unit);
    if (payload.expiry_date !== undefined) assign('expiry_date', payload.expiry_date);
    if (payload.rfid_tag !== undefined && hasRfidColumn) assign('rfid_tag', payload.rfid_tag);
    if (payload.notes !== undefined && hasNotesColumn) assign('notes', payload.notes);

    if (updates.length > 0) {
      const result = await query(
        `update chemicals set ${updates.join(', ')} where id = $1 returning id`,
        [isLegacy ? Number(chemicalId) : chemicalId, ...values]
      );
      if (result.rowCount === 0) return null;
    }

    if (isLegacy && hasChemicalMetadata) {
      const currentMeta = await query(
        'select shelf_code, rfid_tag, notes from chemical_metadata where chemical_id = $1 limit 1',
        [Number(chemicalId)]
      );
      const existingMeta = currentMeta.rows[0] ?? {};
      if (
        payload.shelf_code !== undefined ||
        payload.rfid_tag !== undefined ||
        payload.notes !== undefined
      ) {
        await query(
          `
          insert into chemical_metadata (chemical_id, shelf_code, rfid_tag, notes, updated_at)
          values ($1, $2, $3, $4, now())
          on conflict (chemical_id) do update
          set shelf_code = excluded.shelf_code,
              rfid_tag = excluded.rfid_tag,
              notes = excluded.notes,
              updated_at = now()
          `,
          [
            Number(chemicalId),
            payload.shelf_code ?? existingMeta.shelf_code ?? '',
            payload.rfid_tag ?? existingMeta.rfid_tag ?? null,
            payload.notes ?? existingMeta.notes ?? null
          ]
        );
      }
    }

    if (Array.isArray(payload.responsible_user_ids)) {
      await this.replaceResponsibilities({
        chemicalId,
        userIds: payload.responsible_user_ids,
        assignedBy: operator?.id ?? null
      });
    }

    return this.getById(chemicalId);
  }

  async deleteChemical(chemicalId) {
    if (!isDatabaseConfigured()) {
      const index = memoryChemicals.findIndex((item) => String(item.id) === String(chemicalId));
      if (index === -1) return false;
      memoryChemicals.splice(index, 1);
      return true;
    }
    const isLegacy = await isLegacySchema();
    const normalizedChemicalId = isLegacy ? Number(chemicalId) : chemicalId;

    return withClient(async (client) => {
      await client.query('BEGIN');
      try {
        await client.query(
          'delete from chemical_logs where chemical_id = $1',
          [normalizedChemicalId]
        );
        await client.query(
          'delete from chemical_responsibilities where chemical_id = $1',
          [normalizedChemicalId]
        );
        const result = await client.query(
          'delete from chemicals where id = $1',
          [normalizedChemicalId]
        );
        await client.query('COMMIT');
        return result.rowCount > 0;
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    });
  }

  async replaceResponsibilities({ chemicalId, userIds, assignedBy }) {
    if (!isDatabaseConfigured() || !(await hasTable('chemical_responsibilities'))) {
      return [];
    }
    const isLegacy = await isLegacySchema();
    const normalizedChemicalId = isLegacy ? Number(chemicalId) : chemicalId;
    await query('delete from chemical_responsibilities where chemical_id = $1', [normalizedChemicalId]);
    const normalizedAssignedBy = isLegacy
        ? await this._resolveLegacyUserId(assignedBy)
        : (assignedBy ? String(assignedBy) : null);

    for (const userId of userIds) {
      const normalizedUserId = isLegacy
          ? await this._resolveLegacyUserId(userId)
          : String(userId);
      if (normalizedUserId == null) {
        continue;
      }

      await query(
        `
        insert into chemical_responsibilities (chemical_id, user_id, responsibility_type, assigned_by)
        values ($1, $2, 'custodian', $3)
        on conflict do nothing
        `,
        [normalizedChemicalId, normalizedUserId, normalizedAssignedBy]
      );
    }
    return this.getResponsibilities(chemicalId);
  }

  async _getLegacyResponsibilitiesMap() {
    const map = new Map();
    if (!isDatabaseConfigured() || !(await hasTable('chemical_responsibilities'))) {
      return map;
    }
    const hasNameColumn = await hasColumn('users', 'name');
    const hasRoleColumn = await hasColumn('users', 'role');
    const result = await query(
      `
      select cr.chemical_id,
             u.id::text as user_id,
             ${hasNameColumn ? 'coalesce(u.name, u.username)' : 'u.username'} as name,
             ${hasRoleColumn ? "coalesce(u.role, 'undergraduate')" : "'undergraduate'"} as role
      from chemical_responsibilities cr
      join users u on u.id = cr.user_id
      order by cr.assigned_at asc
      `
    );
    for (const row of result.rows) {
      const key = String(row.chemical_id);
      const current = map.get(key) ?? [];
      current.push({
        id: row.user_id,
        name: row.name,
        role: row.role
      });
      map.set(key, current);
    }
    return map;
  }
}

export const chemicalRepository = new ChemicalRepository();
