BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS media_records (
  id VARCHAR(128) PRIMARY KEY,
  lab_id INTEGER REFERENCES labs(id) ON DELETE SET NULL,
  file_name VARCHAR(255) NOT NULL,
  mime_type VARCHAR(128) NOT NULL,
  size_bytes INTEGER NOT NULL,
  storage_provider VARCHAR(32) NOT NULL DEFAULT 'local',
  storage_url TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by INTEGER REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chemical_responsibilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chemical_id INTEGER NOT NULL REFERENCES chemicals(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  responsibility_type VARCHAR(32) NOT NULL DEFAULT 'custodian',
  assigned_by INTEGER REFERENCES users(id),
  notes TEXT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (chemical_id, user_id, responsibility_type)
);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(128),
  phone VARCHAR(32),
  department VARCHAR(128),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chemical_metadata (
  chemical_id INTEGER PRIMARY KEY REFERENCES chemicals(id) ON DELETE CASCADE,
  shelf_code VARCHAR(64),
  rfid_tag VARCHAR(128),
  notes TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
