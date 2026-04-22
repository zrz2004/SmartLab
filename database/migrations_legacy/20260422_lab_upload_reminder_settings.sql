BEGIN;

CREATE TABLE IF NOT EXISTS lab_upload_reminder_settings (
  lab_id INTEGER PRIMARY KEY REFERENCES labs(id) ON DELETE CASCADE,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  first_reminder_time TIME NOT NULL DEFAULT TIME '19:00',
  second_reminder_time TIME NOT NULL DEFAULT TIME '23:00',
  updated_by INTEGER REFERENCES users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;
