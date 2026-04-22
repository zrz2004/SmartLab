BEGIN;

UPDATE users
SET
  username = 'admin',
  role = 'admin',
  email = 'admin@smartlab.edu'
WHERE id = 1;

INSERT INTO user_profiles (user_id, name, phone, department, updated_at)
VALUES (1, '陈晓江', '13800000001', '院楼806实验室', NOW())
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

UPDATE users
SET
  username = 'lierfan',
  password_hash = '$2b$10$YUMHbnsk6O.gxKvyv5OtQOzQRt.pMnY/r4IhPOSyFwi/2E7Te7oBO',
  email = 'lierfan@smartlab.edu',
  role = 'graduate'
WHERE username = 'tester01';

WITH upserted AS (
  INSERT INTO users (username, password_hash, email, role)
  VALUES ('lierfan', '$2b$10$YUMHbnsk6O.gxKvyv5OtQOzQRt.pMnY/r4IhPOSyFwi/2E7Te7oBO', 'lierfan@smartlab.edu', 'graduate')
  ON CONFLICT (username) DO UPDATE
  SET
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    role = EXCLUDED.role
  RETURNING id
)
INSERT INTO user_profiles (user_id, name, phone, department, updated_at)
SELECT id, '李尔凡', '13800000003', '院楼806实验室', NOW()
FROM upserted
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

WITH upserted AS (
  INSERT INTO users (username, password_hash, email, role)
  VALUES ('xudan', '$2b$10$YUMHbnsk6O.gxKvyv5OtQOzQRt.pMnY/r4IhPOSyFwi/2E7Te7oBO', 'xudan@smartlab.edu', 'teacher')
  ON CONFLICT (username) DO UPDATE
  SET
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    role = EXCLUDED.role
  RETURNING id
)
INSERT INTO user_profiles (user_id, name, phone, department, updated_at)
SELECT id, '徐丹', '13800000002', '院楼806实验室', NOW()
FROM upserted
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

WITH upserted AS (
  INSERT INTO users (username, password_hash, email, role)
  VALUES ('zhangrunzhe', '$2b$10$YUMHbnsk6O.gxKvyv5OtQOzQRt.pMnY/r4IhPOSyFwi/2E7Te7oBO', 'zhangrunzhe@smartlab.edu', 'graduate')
  ON CONFLICT (username) DO UPDATE
  SET
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    role = EXCLUDED.role
  RETURNING id
)
INSERT INTO user_profiles (user_id, name, phone, department, updated_at)
SELECT id, '张润哲', '13800000004', '院楼806实验室', NOW()
FROM upserted
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

WITH upserted AS (
  INSERT INTO users (username, password_hash, email, role)
  VALUES ('leiqian', '$2b$10$YUMHbnsk6O.gxKvyv5OtQOzQRt.pMnY/r4IhPOSyFwi/2E7Te7oBO', 'leiqian@smartlab.edu', 'graduate')
  ON CONFLICT (username) DO UPDATE
  SET
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    role = EXCLUDED.role
  RETURNING id
)
INSERT INTO user_profiles (user_id, name, phone, department, updated_at)
SELECT id, '雷倩', '13800000005', '院楼806实验室', NOW()
FROM upserted
ON CONFLICT (user_id) DO UPDATE
SET
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  department = EXCLUDED.department,
  updated_at = NOW();

INSERT INTO user_lab_access (user_id, lab_id, granted_by)
SELECT u.id, 1, 1
FROM users u
WHERE u.username IN ('admin', 'xudan', 'lierfan', 'zhangrunzhe', 'leiqian')
ON CONFLICT (user_id, lab_id) DO NOTHING;

INSERT INTO user_lab_access (user_id, lab_id, granted_by)
SELECT u.id, 2, 1
FROM users u
WHERE u.username IN ('admin', 'xudan', 'lierfan', 'zhangrunzhe', 'leiqian')
ON CONFLICT (user_id, lab_id) DO NOTHING;

COMMIT;
