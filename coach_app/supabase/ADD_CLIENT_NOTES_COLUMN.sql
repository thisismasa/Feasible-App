-- Add missing client_notes column to sessions table
-- This is required for the enterprise booking system (Phase 1)

ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS client_notes TEXT;

COMMENT ON COLUMN sessions.client_notes IS 'Notes provided by client during booking';

-- Verify
SELECT
  '✅ Column added successfully' as status,
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
  AND column_name = 'client_notes';
