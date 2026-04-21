BEGIN;

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

INSERT INTO user_role_assignments (user_id, role_id, assigned_by)
SELECT u.id, r.id, u.id
FROM users u
JOIN roles r ON r.code = coalesce(u.role, 'undergraduate')
ON CONFLICT DO NOTHING;

INSERT INTO user_lab_access (user_id, lab_id, granted_by)
SELECT 1, l.id, 1
FROM labs l
WHERE l.id IN (1, 2)
ON CONFLICT DO NOTHING;

COMMIT;
