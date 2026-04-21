BEGIN;

INSERT INTO labs (id, name, building_id, building_name, floor, room_number, type, description, safety_score)
VALUES
  ('lab_yuanlou_806', 'Yuanlou 806', 'building_yuanlou', 'School of Information Science Building', '8F', '806', 'computer', 'Computer lab', 96),
  ('lab_xixue_xinke', 'Xixue Xinke Lab', 'building_xixue', 'Xixue Building', '1F', '101', 'electronics', 'Electronics lab', 92)
ON CONFLICT (id) DO NOTHING;

INSERT INTO roles (code, name, description)
VALUES
  ('admin', 'Admin', 'Full system management access'),
  ('teacher', 'Teacher', 'Lab manager and reviewer'),
  ('graduate', 'Graduate', 'Can inspect and control partial devices'),
  ('undergraduate', 'Assistant', 'Read-only assistant role')
ON CONFLICT (code) DO NOTHING;

INSERT INTO permissions (code, name, description)
VALUES
  ('auth.review_registration', 'Review registrations', 'Approve or reject registration requests'),
  ('lab.switch', 'Switch lab', 'Switch current lab context'),
  ('device.control', 'Control devices', 'Control doors, windows, power, and water devices'),
  ('alert.acknowledge', 'Acknowledge alerts', 'Acknowledge sensor and AI alerts'),
  ('chemical.manage', 'Manage chemicals', 'Check in, check out, and audit chemicals'),
  ('inspection.create', 'Create inspections', 'Upload images and trigger AI inspections')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON (
  (r.code = 'admin')
  OR (r.code = 'teacher' AND p.code IN ('auth.review_registration', 'lab.switch', 'device.control', 'alert.acknowledge', 'chemical.manage', 'inspection.create'))
  OR (r.code = 'graduate' AND p.code IN ('lab.switch', 'device.control', 'alert.acknowledge', 'inspection.create'))
  OR (r.code = 'undergraduate' AND p.code IN ('lab.switch', 'inspection.create'))
)
ON CONFLICT DO NOTHING;

INSERT INTO users (username, password_hash, name, role, department, phone, email, is_active)
VALUES
  ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'System Admin', 'admin', 'SmartLab', '13800000000', 'admin@smartlab.edu', TRUE),
  ('teacher', 'cde383eee8ee7a4400adf7a15f716f179a2eb97646b37e089eb8d6d04e663416', 'Lab Teacher', 'teacher', 'School of Information Science', '13800000001', 'teacher@smartlab.edu', TRUE),
  ('graduate', '05f8e4075d17070004bfd691cffa9f76732621974dcf9ba0924300e0cbc5def9', 'Graduate Student', 'graduate', 'School of Information Science', '13800000002', 'graduate@smartlab.edu', TRUE),
  ('student', '703b0a3d6ad75b649a28adde7d83c6251da457549263bc7ff45ec709b0a8448b', 'Lab Assistant', 'undergraduate', 'School of Information Science', '13800000003', 'student@smartlab.edu', TRUE)
ON CONFLICT (username) DO NOTHING;

INSERT INTO user_role_assignments (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = u.role
ON CONFLICT DO NOTHING;

INSERT INTO user_lab_access (user_id, lab_id)
SELECT u.id, l.id
FROM users u
JOIN labs l ON (
  (u.username IN ('admin', 'teacher') AND l.id IN ('lab_yuanlou_806', 'lab_xixue_xinke'))
  OR (u.username IN ('graduate', 'student') AND l.id = 'lab_yuanlou_806')
)
ON CONFLICT DO NOTHING;

INSERT INTO devices (id, name, type, lab_id, position, room_id, building_id, status, firmware_version, protocol, telemetry)
VALUES
  ('yl806_env_01', 'Env Sensor 1', 'environmentSensor', 'lab_yuanlou_806', 'Ceiling center', '806', 'building_yuanlou', 'online', 'v2.1.3', 'MQTT / HTTP', '{"temperature": 24.2, "humidity": 46.5}'::jsonb),
  ('yl806_pwr_01', 'Power Monitor', 'powerMonitor', 'lab_yuanlou_806', 'Power cabinet', '806', 'building_yuanlou', 'online', 'v2.1.3', 'MQTT / HTTP', '{"leakageCurrent": 5.2, "power": 1630}'::jsonb),
  ('xx_pwr_01', 'Power Monitor', 'powerMonitor', 'lab_xixue_xinke', 'Power cabinet', '101', 'building_xixue', 'warning', 'v2.1.3', 'MQTT / HTTP', '{"leakageCurrent": 12.3, "power": 1650}'::jsonb),
  ('xx_water_01', 'Water Sensor', 'waterSensor', 'lab_xixue_xinke', 'Sink area', '101', 'building_xixue', 'online', 'v2.1.3', 'MQTT / HTTP', '{"waterLeak": false}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO chemicals (id, lab_id, name, cas_number, cabinet_id, shelf_code, hazard_class, status, quantity, unit, expiry_date, rfid_tag, notes)
VALUES
  ('chem_yl_001', 'lab_yuanlou_806', 'Isopropyl Alcohol', '67-63-0', 'CAB-01', '01-02', 'flammable', 'inStock', 6, 'bottles', NOW() + INTERVAL '120 days', 'RFID-YL-001', 'Use in ventilated area'),
  ('chem_xx_001', 'lab_xixue_xinke', 'Acetone', '67-64-1', 'CAB-A', 'A-01', 'flammable', 'inStock', 4, 'bottles', NOW() + INTERVAL '180 days', 'RFID-XX-001', 'Store away from heat')
ON CONFLICT (id) DO NOTHING;

INSERT INTO chemical_logs (id, chemical_id, action, quantity, performed_by, notes, timestamp)
VALUES
  ('chem_log_001', 'chem_yl_001', 'audit', 6, 'system', 'Initial inventory sync', NOW() - INTERVAL '2 hours')
ON CONFLICT (id) DO NOTHING;

INSERT INTO alerts (id, type, level, title, message, device_id, device_name, room_id, building_id, lab_id, timestamp, snapshot, is_acknowledged, source, review_status)
VALUES
  ('alert_sensor_001', 'temperatureHigh', 'warning', 'Temperature warning', 'Temperature reached 28.5 C in Yuanlou 806.', 'yl806_env_01', 'Env Sensor 1', '806', 'building_yuanlou', 'lab_yuanlou_806', NOW() - INTERVAL '15 minutes', '{"source":"sensor","metric":"temperature","value":28.5}'::jsonb, FALSE, 'sensor', 'pending_review'),
  ('alert_power_001', 'leakageCurrent', 'critical', 'Leakage current critical', 'Leakage current reached 32mA in Xixue Xinke Lab.', 'xx_pwr_01', 'Power Monitor', '101', 'building_xixue', 'lab_xixue_xinke', NOW() - INTERVAL '1 hour', '{"source":"sensor","metric":"leakage_current","value":32}'::jsonb, FALSE, 'sensor', 'pending_review')
ON CONFLICT (id) DO NOTHING;

COMMIT;
