-- ============================================================================
-- ADD GOOGLE CALENDAR EVENT ID TO SESSIONS TABLE (SAFE VERSION)
-- ============================================================================
-- This script safely adds the google_calendar_event_id column
-- It checks if tables exist first and provides helpful diagnostics
-- ============================================================================

-- STEP 1: Check if sessions table exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'sessions'
  ) THEN
    RAISE NOTICE '❌ ERROR: sessions table does not exist!';
    RAISE NOTICE 'Please check your database schema.';
    RAISE NOTICE 'Run CHECK_TABLES.sql to see what tables exist.';
    RAISE EXCEPTION 'Cannot proceed without sessions table';
  ELSE
    RAISE NOTICE '✅ sessions table exists';
  END IF;
END $$;

-- STEP 2: Add column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'sessions'
    AND column_name = 'google_calendar_event_id'
  ) THEN
    ALTER TABLE sessions ADD COLUMN google_calendar_event_id TEXT;
    RAISE NOTICE '✅ Added google_calendar_event_id column';
  ELSE
    RAISE NOTICE 'ℹ️ google_calendar_event_id column already exists';
  END IF;
END $$;

-- STEP 3: Add comment to document the column
COMMENT ON COLUMN sessions.google_calendar_event_id IS
'Google Calendar Event ID for syncing with trainer calendar';

-- STEP 4: Create index for quick lookup
CREATE INDEX IF NOT EXISTS idx_sessions_google_calendar_event_id
ON sessions(google_calendar_event_id)
WHERE google_calendar_event_id IS NOT NULL;

RAISE NOTICE '✅ Index created';

-- STEP 5: Verify the column was added
SELECT
  '✅ VERIFICATION' as status,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
  AND column_name = 'google_calendar_event_id';

-- STEP 6: Show current sessions structure (safe - only shows structure if data exists)
DO $$
DECLARE
  session_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO session_count FROM sessions;

  IF session_count > 0 THEN
    RAISE NOTICE '✅ Found % sessions in database', session_count;
  ELSE
    RAISE NOTICE 'ℹ️ No sessions found in database yet';
  END IF;
END $$;

-- Show sample of recent sessions (if any exist)
SELECT
  id,
  client_id,
  trainer_id,
  scheduled_start,
  scheduled_end,
  google_calendar_event_id,
  CASE
    WHEN google_calendar_event_id IS NOT NULL THEN '✅ Synced'
    ELSE '⏳ Not synced'
  END as sync_status
FROM sessions
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT '🎉 Google Calendar integration is ready!' as message;
SELECT 'All new bookings will sync to Google Calendar automatically' as next_steps;
