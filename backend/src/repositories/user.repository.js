import {
  createId,
  getPermissionsForRole as getMemoryPermissionsForRole,
  issueTokens,
  labs as memoryLabs,
  registrationRequests as memoryRequests,
  sanitizeUser as sanitizeMemoryUser,
  users as memoryUsers
} from '../data/store.js';
import { hasTable, isDatabaseConfigured, isLegacySchema, query } from '../db.js';
import { getSupportedLegacyLabIds, toDatabaseLabId, toExternalLabId } from '../utils/lab-mapper.js';
import { hashPassword, comparePassword } from '../utils/password.js';

function buildLegacyDisplayName(user) {
  return user.name ?? user.full_name ?? user.username ?? 'User';
}

class UserRepository {
  async findById(id) {
    if (!isDatabaseConfigured()) {
      return memoryUsers.find((item) => String(item.id) === String(id)) ?? null;
    }

    if (await isLegacySchema()) {
      const result = await query('select * from users where id = $1 limit 1', [id]);
      if (result.rowCount === 0) return null;

      const user = result.rows[0];
      const accessibleLabIds = await this._getLegacyAccessibleLabIds(user);
      return {
        id: user.id,
        username: user.username,
        name: buildLegacyDisplayName(user),
        role: user.role ?? 'undergraduate',
        department: user.department ?? 'SmartLab',
        phone: user.phone ?? null,
        email: user.email ?? null,
        avatarUrl: null,
        accessibleLabIds,
        currentLabId: null,
        lastLoginAt: user.last_login_at ?? user.created_at ?? null,
        isActive: user.is_active ?? true
      };
    }

    const result = await query(
      `
      select
        u.id,
        u.username,
        u.name,
        u.department,
        u.phone,
        u.email,
        u.avatar_url,
        u.last_login_at,
        u.is_active,
        coalesce(r.code, u.role, 'undergraduate') as role
      from users u
      left join user_role_assignments ura on ura.user_id = u.id
      left join roles r on r.id = ura.role_id
      where u.id = $1
      limit 1
      `,
      [id]
    );
    if (result.rowCount === 0) return null;

    const user = result.rows[0];
    const access = await query('select lab_id from user_lab_access where user_id = $1 order by lab_id', [id]);

    return {
      id: user.id,
      username: user.username,
      name: user.name,
      role: user.role,
      department: user.department,
      phone: user.phone,
      email: user.email,
      avatarUrl: user.avatar_url,
      accessibleLabIds: access.rows.map((row) => row.lab_id),
      currentLabId: null,
      lastLoginAt: user.last_login_at,
      isActive: user.is_active
    };
  }

  async findByUsername(username) {
    if (!isDatabaseConfigured()) {
      return memoryUsers.find((item) => item.username === username) ?? null;
    }

    if (await isLegacySchema()) {
      const result = await query('select * from users where username = $1 limit 1', [username]);
      if (result.rowCount === 0) return null;

      const user = result.rows[0];
      const accessibleLabIds = await this._getLegacyAccessibleLabIds(user);
      return {
        id: user.id,
        username: user.username,
        password_hash: user.password_hash,
        name: buildLegacyDisplayName(user),
        role: user.role ?? 'undergraduate',
        department: user.department ?? 'SmartLab',
        phone: user.phone ?? null,
        email: user.email ?? null,
        avatarUrl: null,
        accessibleLabIds,
        currentLabId: null,
        lastLoginAt: user.last_login_at ?? user.created_at ?? null,
        isActive: user.is_active ?? true,
        registrationStatus: 'approved'
      };
    }

    const result = await query('select * from users where username = $1 limit 1', [username]);
    if (result.rowCount === 0) return null;

    const user = result.rows[0];
    const access = await query('select lab_id from user_lab_access where user_id = $1 order by lab_id', [user.id]);
    const roleRow = await query(
      `
      select r.code
      from user_role_assignments ura
      join roles r on r.id = ura.role_id
      where ura.user_id = $1
      order by ura.assigned_at asc
      limit 1
      `,
      [user.id]
    );

    return {
      id: user.id,
      username: user.username,
      password: user.password ?? null,
      password_hash: user.password_hash,
      name: user.name,
      role: roleRow.rows[0]?.code ?? user.role ?? 'undergraduate',
      department: user.department,
      phone: user.phone,
      email: user.email,
      avatarUrl: user.avatar_url,
      accessibleLabIds: access.rows.map((row) => row.lab_id),
      currentLabId: null,
      lastLoginAt: user.last_login_at,
      isActive: user.is_active,
      registrationStatus: 'approved'
    };
  }

  async authenticate(username, password) {
    const user = await this.findByUsername(username);
    if (!user) return null;

    const passwordMatches = isDatabaseConfigured()
        ? comparePassword(password, user.password_hash ?? '')
        : user.password === password;

    if (!passwordMatches || user.isActive == false || user.registrationStatus === 'pending_review') {
      return null;
    }

    if (isDatabaseConfigured()) {
      const canPersistLastLogin = !(await isLegacySchema()) || (await hasTable('users'));
      if (canPersistLastLogin) {
        try {
          await query('update users set last_login_at = now() where id = $1', [user.id]);
        } catch (_) {
          // ignore when legacy table does not have last_login_at yet
        }
      }
    } else {
      user.lastLoginAt = new Date().toISOString();
    }

    const tokens = issueTokens(user.id);
    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user
    };
  }

  sanitizeUser(user) {
    if (!isDatabaseConfigured()) {
      return sanitizeMemoryUser(user);
    }
    return {
      id: user.id,
      username: user.username,
      name: user.name,
      role: user.role,
      department: user.department,
      phone: user.phone,
      email: user.email,
      avatar_url: user.avatarUrl ?? null,
      accessible_lab_ids: user.accessibleLabIds ?? [],
      last_login_at: user.lastLoginAt ?? null,
      is_active: user.isActive ?? true
    };
  }

  async getPermissionsForUser(user) {
    if (!isDatabaseConfigured()) {
      return getMemoryPermissionsForRole(user.role);
    }

    if (!(await hasTable('roles')) || !(await hasTable('role_permissions'))) {
      return getMemoryPermissionsForRole(user.role);
    }

    const result = await query(
      `
      select p.code
      from user_role_assignments ura
      join role_permissions rp on rp.role_id = ura.role_id
      join permissions p on p.id = rp.permission_id
      where ura.user_id = $1
      order by p.code
      `,
      [user.id]
    );
    return result.rows.map((row) => row.code);
  }

  async getAccessibleLabs(user) {
    if (!isDatabaseConfigured()) {
      return memoryLabs.filter((item) => user.role === 'admin' || user.accessibleLabIds.includes(item.id));
    }

    if (await isLegacySchema()) {
      const supportedLabIds = getSupportedLegacyLabIds();
      const selectedLabIds = user.role === 'admin'
          ? supportedLabIds
          : (await this._getLegacyAccessibleLabIds(user)).map((labId) => toDatabaseLabId(labId)).filter(Boolean);

      if (selectedLabIds.length === 0) {
        return [];
      }

      const result = await query(
        `
        select l.id, l.name, l.room_number, l.floor, l.safety_score, l.building_id, b.name as building_name
        from labs l
        left join buildings b on b.id = l.building_id
        where l.id = any($1::int[])
        order by l.id
        `,
        [selectedLabIds]
      );
      return result.rows.map((row) => ({
        id: toExternalLabId(row.id),
        database_id: row.id,
        name: row.name,
        room_number: row.room_number,
        floor: row.floor != null ? `${row.floor}F` : '',
        building_id: String(row.building_id ?? ''),
        building_name: row.building_name ?? 'SmartLab Building',
        safety_score: Number(row.safety_score ?? 100),
        type: 'general',
        status: 'normal'
      }));
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

  async listPendingRegistrations() {
    if (!isDatabaseConfigured()) {
      return memoryRequests.map((item) => ({
        id: item.id,
        username: item.username,
        name: item.name,
        email: item.email,
        phone: item.phone,
        requested_role: item.requestedRole,
        submitted_at: item.submittedAt,
        status: item.status
      }));
    }

    if (!(await hasTable('registration_requests'))) {
      return [];
    }

    const result = await query(
      `
      select id, username, full_name as name, email, phone, requested_role, submitted_at, status
      from registration_requests
      where status = 'pending_review'
      order by submitted_at desc
      `
    );
    return result.rows;
  }

  async createRegistrationRequest(payload) {
    if (!isDatabaseConfigured()) {
      if (memoryRequests.some((item) => item.username === payload.username && item.status === 'pending_review')) {
        throw new Error('Username already has a pending registration request.');
      }
      const request = {
        id: createId('reg'),
        username: payload.username,
        password: payload.password,
        name: payload.name,
        email: payload.email,
        phone: payload.phone ?? '',
        requestedRole: payload.requestedRole,
        submittedAt: new Date().toISOString(),
        status: 'pending_review'
      };
      memoryRequests.unshift(request);
      return {
        requestId: request.id,
        status: request.status,
        submittedAt: request.submittedAt
      };
    }

    if (!(await hasTable('registration_requests'))) {
      throw new Error('registration_requests table is missing.');
    }

    const result = await query(
      `
      insert into registration_requests (username, full_name, email, phone, requested_role, password_hash, status)
      values ($1, $2, $3, $4, $5, $6, 'pending_review')
      returning id, submitted_at, status
      `,
      [
        payload.username,
        payload.name,
        payload.email,
        payload.phone ?? '',
        payload.requestedRole,
        hashPassword(payload.password)
      ]
    );

    return {
      requestId: result.rows[0].id,
      status: result.rows[0].status,
      submittedAt: result.rows[0].submitted_at
    };
  }

  async approveRegistration(requestId, role, labIds) {
    if (!isDatabaseConfigured()) {
      const record = memoryRequests.find((item) => item.id === requestId);
      if (!record) return null;
      record.status = 'approved';
      record.reviewedAt = new Date().toISOString();

      const user = {
        id: createId('user'),
        username: record.username,
        password: record.password,
        name: record.name,
        role,
        email: record.email,
        department: 'School of Information Science',
        phone: record.phone,
        accessibleLabIds: labIds,
        currentLabId: labIds.length === 1 ? labIds[0] : null,
        isActive: true,
        registrationStatus: 'approved',
        lastLoginAt: null
      };
      memoryUsers.push(user);
      return user;
    }

    if (!(await hasTable('registration_requests'))) {
      return null;
    }

    const requestResult = await query('select * from registration_requests where id = $1 limit 1', [requestId]);
    if (requestResult.rowCount === 0) return null;
    const record = requestResult.rows[0];

    let inserted;
    if (await isLegacySchema()) {
      inserted = await query(
        `
        insert into users (username, password_hash, email, role)
        values ($1, $2, $3, $4)
        returning id, username, email, role, created_at
        `,
        [record.username, record.password_hash, record.email, role]
      );
    } else {
      inserted = await query(
        `
        insert into users (username, password_hash, name, role, department, phone, email, is_active)
        values ($1, $2, $3, $4, $5, $6, $7, true)
        returning id, username, name, department, phone, email, role, last_login_at, is_active
        `,
        [
          record.username,
          record.password_hash,
          record.full_name,
          role,
          'School of Information Science',
          record.phone,
          record.email
        ]
      );
    }

    const user = inserted.rows[0];
    if (await hasTable('roles')) {
      const roleRow = await query('select id from roles where code = $1 limit 1', [role]);
      if (roleRow.rowCount > 0) {
        await query('insert into user_role_assignments (user_id, role_id) values ($1, $2) on conflict do nothing', [user.id, roleRow.rows[0].id]);
      }
    }
    for (const labId of labIds) {
      await query('insert into user_lab_access (user_id, lab_id) values ($1, $2) on conflict do nothing', [user.id, toDatabaseLabId(labId)]);
    }
    await query('update registration_requests set status = $2, reviewed_at = now() where id = $1', [requestId, 'approved']);

    return {
      id: user.id,
      username: user.username,
      name: buildLegacyDisplayName(user),
      role,
      email: user.email,
      phone: user.phone ?? null,
      department: user.department ?? 'SmartLab',
      accessibleLabIds: labIds,
      lastLoginAt: user.last_login_at ?? user.created_at ?? null,
      isActive: user.is_active ?? true
    };
  }

  async rejectRegistration(requestId, reason) {
    if (!isDatabaseConfigured()) {
      const request = memoryRequests.find((item) => item.id === requestId);
      if (!request) return false;
      request.status = 'rejected';
      request.rejectReason = reason;
      return true;
    }
    const result = await query(
      'update registration_requests set status = $2, review_comment = $3, reviewed_at = now() where id = $1',
      [requestId, 'rejected', reason]
    );
    return result.rowCount > 0;
  }

  async _getLegacyAccessibleLabIds(user) {
    const supportedLabIds = getSupportedLegacyLabIds();

    if (user.role === 'admin') {
      return supportedLabIds.map((labId) => toExternalLabId(labId));
    }

    if (await hasTable('user_lab_access')) {
      const result = await query(
        'select lab_id from user_lab_access where user_id = $1 and lab_id = any($2::int[]) order by lab_id',
        [user.id, supportedLabIds]
      );
      if (result.rowCount > 0) {
        return result.rows.map((row) => toExternalLabId(row.lab_id));
      }
    }

    const managedLabs = await query(
      'select id from labs where manager_id = $1 and id = any($2::int[]) order by id',
      [user.id, supportedLabIds]
    );
    if (managedLabs.rowCount > 0) {
      return managedLabs.rows.map((row) => toExternalLabId(row.id));
    }

    return [toExternalLabId(supportedLabIds[0])];
  }
}

export const userRepository = new UserRepository();
