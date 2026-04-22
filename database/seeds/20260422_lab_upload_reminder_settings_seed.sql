BEGIN;

INSERT INTO lab_upload_reminder_settings (
  lab_id,
  enabled,
  first_reminder_time,
  second_reminder_time
)
VALUES
  ('lab_yuanlou_806', TRUE, TIME '19:00', TIME '23:00'),
  ('lab_xixue_xinke', TRUE, TIME '19:00', TIME '23:00')
ON CONFLICT (lab_id) DO NOTHING;

COMMIT;
