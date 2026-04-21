BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name VARCHAR(128) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'undergraduate',
  department VARCHAR(128),
  phone VARCHAR(64),
  email VARCHAR(255),
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS labs (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  building_id VARCHAR(64) NOT NULL,
  building_name VARCHAR(128) NOT NULL,
  floor VARCHAR(32) NOT NULL,
  room_number VARCHAR(32) NOT NULL,
  type VARCHAR(64) NOT NULL,
  description TEXT,
  area_sqm NUMERIC(10, 2),
  capacity INTEGER,
  status VARCHAR(32) NOT NULL DEFAULT 'normal',
  safety_score INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
  id VARCHAR(128) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  type VARCHAR(64) NOT NULL,
  lab_id VARCHAR(64) NOT NULL REFERENCES labs(id) ON DELETE CASCADE,
  position VARCHAR(128),
  room_id VARCHAR(32),
  building_id VARCHAR(64),
  status VARCHAR(32) NOT NULL DEFAULT 'offline',
  firmware_version VARCHAR(64),
  protocol VARCHAR(64),
  telemetry JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chemicals (
  id VARCHAR(128) PRIMARY KEY,
  lab_id VARCHAR(64) NOT NULL REFERENCES labs(id) ON DELETE CASCADE,
  name VARCHAR(128) NOT NULL,
  cas_number VARCHAR(64) NOT NULL,
  cabinet_id VARCHAR(64) NOT NULL,
  shelf_code VARCHAR(64),
  hazard_class VARCHAR(64) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'inStock',
  quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
  unit VARCHAR(32) NOT NULL DEFAULT 'bottle',
  expiry_date TIMESTAMPTZ,
  rfid_tag VARCHAR(128),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chemical_logs (
  id VARCHAR(128) PRIMARY KEY,
  chemical_id VARCHAR(128) NOT NULL REFERENCES chemicals(id) ON DELETE CASCADE,
  action VARCHAR(64) NOT NULL,
  quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
  performed_by VARCHAR(128) NOT NULL,
  notes TEXT,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
  id VARCHAR(128) PRIMARY KEY,
  type VARCHAR(64) NOT NULL,
  level VARCHAR(32) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  device_id VARCHAR(128),
  device_name VARCHAR(128),
  room_id VARCHAR(32),
  building_id VARCHAR(64),
  lab_id VARCHAR(64) REFERENCES labs(id),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by VARCHAR(128),
  source VARCHAR(32) NOT NULL DEFAULT 'sensor',
  confidence NUMERIC(5, 4),
  evidence JSONB NOT NULL DEFAULT '[]'::jsonb,
  review_status VARCHAR(32) NOT NULL DEFAULT 'pending_review'
);

COMMIT;
