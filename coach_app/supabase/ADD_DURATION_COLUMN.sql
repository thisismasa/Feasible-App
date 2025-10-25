-- Add missing duration_minutes column to sessions table
-- This is required for the enterprise booking system (Phase 1)

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 60;

COMMENT ON COLUMN sessions.duration_minutes IS 'Session duration in minutes (default 60)';

-- Update existing sessions to have duration based on scheduled_start and scheduled_end
UPDATE sessions
SET duration_minutes = EXTRACT(EPOCH FROM (scheduled_end - scheduled_start)) / 60
WHERE duration_minutes IS NULL
  AND scheduled_start IS NOT NULL
  AND scheduled_end IS NOT NULL;

-- Verify
SELECT
  '✅ Column added successfully' as status,
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
  AND column_name = 'duration_minutes';
