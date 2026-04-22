BEGIN;

INSERT INTO lab_upload_reminder_settings (
  lab_id,
  enabled,
  first_reminder_time,
  second_reminder_time
)
VALUES
  (1, TRUE, TIME '19:00', TIME '23:00'),
  (2, TRUE, TIME '19:00', TIME '23:00')
ON CONFLICT (lab_id) DO NOTHING;

COMMIT;
