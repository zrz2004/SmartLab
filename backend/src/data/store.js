import crypto from 'crypto';

const now = () => new Date().toISOString();

export const labs = [
  {
    id: 'lab_yuanlou_806',
    name: '院楼806实验室',
    buildingId: 'building_yuanlou',
    buildingName: '信息科学楼',
    floor: '8F',
    roomNumber: '806',
    type: 'computer',
    description: '计算机与信息安全实验室'
  },
  {
    id: 'lab_xixue_xinke',
    name: '西学楼一楼信科实验室',
    buildingId: 'building_xixue',
    buildingName: '西学楼',
    floor: '1F',
    roomNumber: '101',
    type: 'electronics',
    description: '信科综合实验室'
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
    name: '实验室管理员',
    role: 'admin',
    email: 'admin@smartlab.edu',
    department: '智慧实验室中心',
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
    name: '值班教师',
    role: 'teacher',
    email: 'teacher@smartlab.edu',
    department: '信息科学学院',
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
    name: '研究生助理',
    role: 'graduate',
    email: 'graduate@smartlab.edu',
    department: '信息科学学院',
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
    name: '实验室助理',
    role: 'undergraduate',
    email: 'student@smartlab.edu',
    department: '信息科学学院',
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
    title: '温度预警',
    message: '院楼806实验室温度达到 28.5°C。',
    device_id: 'yl806_env_01',
    device_name: '环境传感器 1',
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
    title: '漏电流严重警告',
    message: '西学楼一楼信科实验室漏电流达到 32mA。',
    device_id: 'xx_pwr_01',
    device_name: '总电源监测',
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
    name: '环境传感器 1',
    type: 'environmentSensor',
    lab_id: 'lab_yuanlou_806',
    position: '天花板中央',
    status: 'online'
  },
  {
    id: 'yl806_pwr_01',
    name: '总电源监测',
    type: 'powerMonitor',
    lab_id: 'lab_yuanlou_806',
    position: '配电柜',
    status: 'online'
  },
  {
    id: 'xx_pwr_01',
    name: '总电源监测',
    type: 'powerMonitor',
    lab_id: 'lab_xixue_xinke',
    position: '配电柜',
    status: 'warning'
  },
  {
    id: 'xx_water_01',
    name: '水路传感器',
    type: 'waterSensor',
    lab_id: 'lab_xixue_xinke',
    position: '水槽区域',
    status: 'online'
  }
];

export const chemicals = [
  {
    id: 'chem_yl_001',
    lab_id: 'lab_yuanlou_806',
    name: '异丙醇',
    cas_number: '67-63-0',
    cabinet_id: 'CAB-01',
    shelf_code: '01-02',
    hazard_class: 'flammable',
    status: 'inStock',
    quantity: 6,
    unit: '瓶',
    expiry_date: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000).toISOString(),
    rfid_tag: 'RFID-YL-001'
  },
  {
    id: 'chem_xx_001',
    lab_id: 'lab_xixue_xinke',
    name: '丙酮',
    cas_number: '67-64-1',
    cabinet_id: 'CAB-A',
    shelf_code: 'A-01',
    hazard_class: 'flammable',
    status: 'inStock',
    quantity: 4,
    unit: '瓶',
    expiry_date: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000).toISOString(),
    rfid_tag: 'RFID-XX-001'
  }
];

export const chemicalLogs = [
  {
    id: 'chem_log_001',
    chemical_id: 'chem_yl_001',
    action: '盘点',
    quantity: 6,
    performed_by: 'system',
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    notes: '库存已同步'
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
