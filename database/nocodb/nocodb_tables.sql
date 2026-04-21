CREATE TABLE IF NOT EXISTS inspection_media (
  id SERIAL PRIMARY KEY,
  business_record_id VARCHAR(128) NOT NULL,
  inspection_id VARCHAR(128),
  lab_id VARCHAR(64) NOT NULL,
  scene_type VARCHAR(64) NOT NULL,
  device_type VARCHAR(64) NOT NULL,
  target_id VARCHAR(128),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  original_filename VARCHAR(255),
  mime_type VARCHAR(64),
  file_size BIGINT,
  uploaded_by VARCHAR(128),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS manual_reviews (
  id SERIAL PRIMARY KEY,
  inspection_id VARCHAR(128) NOT NULL,
  lab_id VARCHAR(64) NOT NULL,
  reviewer_name VARCHAR(128) NOT NULL,
  review_status VARCHAR(32) NOT NULL,
  review_comment TEXT,
  action_taken TEXT,
  reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
