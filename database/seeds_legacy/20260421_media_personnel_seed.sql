BEGIN;

INSERT INTO user_profiles (user_id, name, phone, department)
SELECT
  u.id,
  CASE u.username
    WHEN 'admin' THEN '实验室管理员'
    WHEN 'teacher' THEN '值班教师'
    ELSE u.username
  END,
  CASE u.username
    WHEN 'admin' THEN '13800000001'
    WHEN 'teacher' THEN '13800000002'
    ELSE NULL
  END,
  '智慧实验室中心'
FROM users u
WHERE u.username IN ('admin', 'teacher')
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

INSERT INTO chemical_metadata (chemical_id, shelf_code, notes)
SELECT
  c.id,
  CASE c.id
    WHEN 1 THEN 'A-01'
    WHEN 2 THEN 'B-03'
    WHEN 3 THEN 'C-02'
    ELSE 'A-01'
  END,
  'Legacy inventory synced'
FROM chemicals c
WHERE c.lab_id IN (1, 2)
ON CONFLICT (chemical_id) DO UPDATE
SET
  shelf_code = EXCLUDED.shelf_code,
  notes = EXCLUDED.notes,
  updated_at = NOW();

INSERT INTO chemical_responsibilities (chemical_id, user_id, responsibility_type, assigned_by, notes)
SELECT c.id, 1, 'custodian', 1, 'Default lab custodian'
FROM chemicals c
ON CONFLICT DO NOTHING;

COMMIT;
