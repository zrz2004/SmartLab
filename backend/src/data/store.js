import crypto from 'crypto';

const now = () => new Date().toISOString();

export const labs = [
  {
    id: 'lab_yuanlou_806',
    name: 'Yuanlou 806',
    buildingId: 'building_yuanlou',
    buildingName: 'School of Information Science Building',
    floor: '8F',
    roomNumber: '806',
    type: 'computer',
    description: 'Computer lab'
  },
  {
    id: 'lab_xixue_xinke',
    name: 'Xixue Xinke Lab',
    buildingId: 'building_xixue',
    buildingName: 'Xixue Building',
    floor: '1F',
    roomNumber: '101',
    type: 'electronics',
    description: 'Electronics lab'
  }
];

export const rolePermissions = {
  admin: [
    'dashboard:view',
    'devices:view',
    'devices:control',
    'device.control',
    'alerts:view',
    'alerts:ack',
    'alert.acknowledge',
    'chemicals:view',
    'chemicals:checkout',
    'chemicals:checkin',
    'chemical.manage',
    'labs:manage',
    'lab.switch',
    'users:review',
    'auth.review_registration',
    'inspection.create'
  ],
  teacher: [
    'dashboard:view',
    'devices:view',
    'devices:control',
    'device.control',
    'alerts:view',
    'alerts:ack',
    'alert.acknowledge',
    'chemicals:view',
    'chemicals:checkout',
    'chemicals:checkin',
    'chemical.manage',
    'labs:manage',
    'lab.switch',
    'auth.review_registration',
    'inspection.create'
  ],
  graduate: [
    'dashboard:view',
    'devices:view',
    'devices:control',
    'device.control',
    'alerts:view',
    'alerts:ack',
    'alert.acknowledge',
    'chemicals:view',
    'chemicals:checkout',
    'lab.switch',
    'inspection.create'
  ],
  undergraduate: ['dashboard:view', 'devices:view', 'alerts:view', 'chemicals:view', 'lab.switch', 'inspection.create']
};

export const users = [
  {
    id: 'user_admin',
    username: 'admin',
    password: 'admin123',
    name: 'System Admin',
    role: 'admin',
    email: 'admin@smartlab.edu',
    department: 'SmartLab',
    phone: '13800000000',
    accessibleLabIds: labs.map((item) => item.id),
    currentLabId: null,
    isActive: true,
    registrationStatus: 'approved',
    lastLoginAt: null
  },
  {
    id: 'user_teacher',
    username: 'teacher',
    password: 'teacher123',
    name: 'Lab Teacher',
    role: 'teacher',
    email: 'teacher@smartlab.edu',
    department: 'School of Information Science',
    phone: '13800000001',
    accessibleLabIds: labs.map((item) => item.id),
    currentLabId: null,
    isActive: true,
    registrationStatus: 'approved',
    lastLoginAt: null
  },
  {
    id: 'user_graduate',
    username: 'graduate',
    password: 'graduate123',
    name: 'Graduate Student',
    role: 'graduate',
    email: 'graduate@smartlab.edu',
    department: 'School of Information Science',
    phone: '13800000002',
    accessibleLabIds: ['lab_yuanlou_806'],
    currentLabId: null,
    isActive: true,
    registrationStatus: 'approved',
    lastLoginAt: null
  },
  {
    id: 'user_student',
    username: 'student',
    password: 'student123',
    name: 'Lab Assistant',
    role: 'undergraduate',
    email: 'student@smartlab.edu',
    department: 'School of Information Science',
    phone: '13800000003',
    accessibleLabIds: ['lab_yuanlou_806'],
    currentLabId: null,
    isActive: true,
    registrationStatus: 'approved',
    lastLoginAt: null
  }
];

export const registrationRequests = [];
export const sessions = new Map();
export const refreshSessions = new Map();
export const mediaRecords = [];
export const aiInspections = [];

export const alerts = [
  {
    id: 'alert_sensor_001',
    type: 'temperatureHigh',
    level: 'warning',
    title: 'Temperature warning',
    message: 'Temperature reached 28.5 C in Yuanlou 806.',
    device_id: 'yl806_env_01',
    device_name: 'Env Sensor 1',
    room_id: '806',
    building_id: 'building_yuanlou',
    timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    snapshot: { source: 'sensor', metric: 'temperature', value: 28.5 },
    is_acknowledged: false
  },
  {
    id: 'alert_power_001',
    type: 'leakageCurrent',
    level: 'critical',
    title: 'Leakage current critical',
    message: 'Leakage current reached 32mA in Xixue Xinke Lab.',
    device_id: 'xx_pwr_01',
    device_name: 'Power Monitor',
    room_id: '101',
    building_id: 'building_xixue',
    timestamp: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
    snapshot: { source: 'sensor', metric: 'leakage_current', value: 32 },
    is_acknowledged: false
  }
];

export const devices = [
  {
    id: 'yl806_env_01',
    name: 'Env Sensor 1',
    type: 'environmentSensor',
    lab_id: 'lab_yuanlou_806',
    position: 'Ceiling center',
    status: 'online'
  },
  {
    id: 'yl806_pwr_01',
    name: 'Power Monitor',
    type: 'powerMonitor',
    lab_id: 'lab_yuanlou_806',
    position: 'Power cabinet',
    status: 'online'
  },
  {
    id: 'xx_pwr_01',
    name: 'Power Monitor',
    type: 'powerMonitor',
    lab_id: 'lab_xixue_xinke',
    position: 'Power cabinet',
    status: 'warning'
  },
  {
    id: 'xx_water_01',
    name: 'Water Sensor',
    type: 'waterSensor',
    lab_id: 'lab_xixue_xinke',
    position: 'Sink area',
    status: 'online'
  }
];

export const chemicals = [
  {
    id: 'chem_yl_001',
    lab_id: 'lab_yuanlou_806',
    name: 'Isopropyl Alcohol',
    cas_number: '67-63-0',
    cabinet_id: 'CAB-01',
    shelf_code: '01-02',
    hazard_class: 'flammable',
    status: 'inStock',
    quantity: 6,
    unit: 'bottles',
    expiry_date: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000).toISOString(),
    rfid_tag: 'RFID-YL-001'
  },
  {
    id: 'chem_xx_001',
    lab_id: 'lab_xixue_xinke',
    name: 'Acetone',
    cas_number: '67-64-1',
    cabinet_id: 'CAB-A',
    shelf_code: 'A-01',
    hazard_class: 'flammable',
    status: 'inStock',
    quantity: 4,
    unit: 'bottles',
    expiry_date: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(),
    rfid_tag: 'RFID-XX-001'
  }
];

export const chemicalLogs = [
  {
    id: 'chem_log_001',
    chemical_id: 'chem_yl_001',
    action: 'audit',
    quantity: 6,
    performed_by: 'system',
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    notes: 'Inventory synced'
  }
];

export function createId(prefix) {
  return `${prefix}_${crypto.randomBytes(6).toString('hex')}`;
}

export function createToken(prefix) {
  return `${prefix}_${crypto.randomBytes(24).toString('hex')}`;
}

export function sanitizeUser(user) {
  return {
    id: user.id,
    username: user.username,
    name: user.name,
    role: user.role,
    department: user.department,
    phone: user.phone,
    email: user.email,
    accessible_lab_ids: user.accessibleLabIds,
    last_login_at: user.lastLoginAt,
    is_active: user.isActive
  };
}

export function getUserByAccessToken(token) {
  const session = sessions.get(token);
  if (!session) return null;
  return { userId: session.userId, issuedAt: session.issuedAt };
}

export function getUserByRefreshToken(token) {
  const session = refreshSessions.get(token);
  if (!session) return null;
  return { userId: session.userId, issuedAt: session.issuedAt };
}

export function issueTokens(userId) {
  const accessToken = createToken('sl_access');
  const refreshToken = createToken('sl_refresh');

  sessions.set(accessToken, { userId, issuedAt: now() });
  refreshSessions.set(refreshToken, { userId, issuedAt: now() });

  return { accessToken, refreshToken };
}

export function revokeAccessToken(token) {
  sessions.delete(token);
}

export function revokeRefreshToken(token) {
  refreshSessions.delete(token);
}

export function getPermissionsForRole(role) {
  return rolePermissions[role] ?? [];
}
