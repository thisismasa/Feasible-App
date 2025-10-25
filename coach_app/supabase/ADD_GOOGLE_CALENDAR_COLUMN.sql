-- ============================================================================
-- ADD GOOGLE CALENDAR EVENT ID TO SESSIONS TABLE
-- ============================================================================
-- This allows us to track which Google Calendar event corresponds to each session
-- so we can update or delete events when sessions are rescheduled or cancelled
-- ============================================================================

-- Add column to sessions table
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS google_calendar_event_id TEXT;

-- Add comment to document the column
COMMENT ON COLUMN sessions.google_calendar_event_id IS 
'Google Calendar Event ID for syncing with trainer calendar';

-- Create index for quick lookup
CREATE INDEX IF NOT EXISTS idx_sessions_google_calendar_event_id
ON sessions(google_calendar_event_id)
WHERE google_calendar_event_id IS NOT NULL;

-- Verify the column was added
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
  AND column_name = 'google_calendar_event_id';

-- Show sample data structure
SELECT
  id,
  client_id,
  trainer_id,
  scheduled_start,
  scheduled_end,
  google_calendar_event_id,
  CASE 
    WHEN google_calendar_event_id IS NOT NULL THEN '✅ Synced to Google Calendar'
    ELSE '⏳ Not yet synced'
  END as sync_status
FROM sessions
ORDER BY scheduled_start DESC
LIMIT 5;

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- Column: google_calendar_event_id
-- Type: text
-- Nullable: YES
-- Default: null
--
-- All existing sessions will have NULL google_calendar_event_id
-- New bookings will store the Google Calendar event ID after creation
-- ============================================================================
