-- ============================================================================
-- GOOGLE CALENDAR SYNC SETUP - Complete Integration
-- ============================================================================
-- This script ensures Google Calendar integration is properly configured
-- ============================================================================

-- ============================================================================
-- STEP 1: Ensure google_calendar_event_id column exists
-- ============================================================================

-- Add column if it doesn't exist
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS google_calendar_event_id TEXT;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_sessions_google_calendar_event_id
ON sessions(google_calendar_event_id)
WHERE google_calendar_event_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN sessions.google_calendar_event_id IS
'Google Calendar Event ID - stores the event ID from Google Calendar API for sync operations (update/delete)';

-- ============================================================================
-- STEP 2: Create function to check calendar sync status
-- ============================================================================

CREATE OR REPLACE FUNCTION check_calendar_sync_status(p_trainer_id UUID)
RETURNS TABLE (
  total_sessions BIGINT,
  synced_sessions BIGINT,
  unsynced_sessions BIGINT,
  sync_rate NUMERIC(5,2),
  recent_unsynced_sessions JSON
) AS $$
BEGIN
  RETURN QUERY
  WITH session_stats AS (
    SELECT
      COUNT(*) as total,
      COUNT(google_calendar_event_id) as synced,
      COUNT(*) - COUNT(google_calendar_event_id) as unsynced
    FROM sessions
    WHERE trainer_id = p_trainer_id
      AND status IN ('scheduled', 'confirmed')
      AND scheduled_start >= NOW()
  ),
  unsynced AS (
    SELECT json_agg(
      json_build_object(
        'session_id', id,
        'client_id', client_id,
        'scheduled_start', scheduled_start,
        'scheduled_end', scheduled_end,
        'created_at', created_at
      )
    ) as recent_unsynced
    FROM (
      SELECT id, client_id, scheduled_start, scheduled_end, created_at
      FROM sessions
      WHERE trainer_id = p_trainer_id
        AND status IN ('scheduled', 'confirmed')
        AND scheduled_start >= NOW()
        AND google_calendar_event_id IS NULL
      ORDER BY created_at DESC
      LIMIT 10
    ) s
  )
  SELECT
    total,
    synced,
    unsynced,
    CASE WHEN total > 0 THEN ROUND((synced::NUMERIC / total) * 100, 2) ELSE 0 END as sync_rate,
    recent_unsynced
  FROM session_stats, unsynced;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_calendar_sync_status IS 'Check Google Calendar sync status for a trainer';

-- ============================================================================
-- STEP 3: Create view for calendar sync monitoring
-- ============================================================================

CREATE OR REPLACE VIEW calendar_sync_status AS
SELECT
  s.id as session_id,
  s.trainer_id,
  t.full_name as trainer_name,
  s.client_id,
  c.full_name as client_name,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.google_calendar_event_id,
  CASE
    WHEN s.google_calendar_event_id IS NOT NULL THEN '✅ Synced'
    WHEN s.status = 'cancelled' THEN '🚫 Cancelled'
    WHEN s.scheduled_start < NOW() THEN '⏰ Past Event'
    ELSE '⏳ Not Synced'
  END as sync_status,
  s.created_at as booked_at,
  s.updated_at as last_updated
FROM sessions s
LEFT JOIN users t ON s.trainer_id = t.id
LEFT JOIN users c ON s.client_id = c.id
WHERE s.status IN ('scheduled', 'confirmed', 'in_progress')
ORDER BY s.scheduled_start ASC;

COMMENT ON VIEW calendar_sync_status IS 'Monitor Google Calendar sync status for all sessions';

-- ============================================================================
-- STEP 4: Create function to mark sessions as calendar-synced
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_session_calendar_synced(
  p_session_id UUID,
  p_calendar_event_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE sessions
  SET
    google_calendar_event_id = p_calendar_event_id,
    updated_at = NOW()
  WHERE id = p_session_id;

  -- FOUND is automatically set by PostgreSQL after UPDATE/INSERT/DELETE
  IF FOUND THEN
    RAISE NOTICE '✅ Session % synced to Google Calendar: %', p_session_id, p_calendar_event_id;
    RETURN TRUE;
  ELSE
    RAISE WARNING '❌ Session % not found', p_session_id;
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION mark_session_calendar_synced IS 'Mark a session as synced to Google Calendar';

-- ============================================================================
-- STEP 5: Create function to batch sync sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION get_unsynced_sessions(p_trainer_id UUID, p_limit INT DEFAULT 50)
RETURNS TABLE (
  session_id UUID,
  client_id UUID,
  client_name TEXT,
  client_email TEXT,
  scheduled_start TIMESTAMPTZ,
  scheduled_end TIMESTAMPTZ,
  duration_minutes INT,
  session_type TEXT,
  location TEXT,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id as session_id,
    s.client_id,
    u.full_name as client_name,
    u.email as client_email,
    s.scheduled_start,
    s.scheduled_end,
    EXTRACT(EPOCH FROM (s.scheduled_end - s.scheduled_start))::INT / 60 as duration_minutes,
    s.session_type,
    s.location,
    s.notes
  FROM sessions s
  LEFT JOIN users u ON s.client_id = u.id
  WHERE s.trainer_id = p_trainer_id
    AND s.status IN ('scheduled', 'confirmed')
    AND s.scheduled_start >= NOW()
    AND s.google_calendar_event_id IS NULL
  ORDER BY s.scheduled_start ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_unsynced_sessions IS 'Get sessions that need to be synced to Google Calendar';

-- ============================================================================
-- STEP 6: Verification queries
-- ============================================================================

-- Check column exists
SELECT
  '✅ google_calendar_event_id column exists' as status,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'sessions'
  AND column_name = 'google_calendar_event_id';

-- Check index exists
SELECT
  '✅ Calendar event ID index exists' as status,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'sessions'
  AND indexname = 'idx_sessions_google_calendar_event_id';

-- Check function exists
SELECT
  '✅ Calendar sync functions created' as status,
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%calendar%'
ORDER BY routine_name;

-- Show sample calendar sync status
SELECT * FROM calendar_sync_status
LIMIT 5;

-- ============================================================================
-- STEP 7: Usage examples
-- ============================================================================

/*
-- Check sync status for a trainer:
SELECT * FROM check_calendar_sync_status('trainer-uuid-here');

-- Get unsynced sessions for batch processing:
SELECT * FROM get_unsynced_sessions('trainer-uuid-here', 20);

-- Mark a session as synced:
SELECT mark_session_calendar_synced(
  'session-uuid-here',
  'google-calendar-event-id-here'
);

-- View all sessions sync status:
SELECT * FROM calendar_sync_status
WHERE trainer_id = 'trainer-uuid-here'
ORDER BY scheduled_start;

-- Count sessions by sync status:
SELECT
  sync_status,
  COUNT(*) as count
FROM calendar_sync_status
WHERE trainer_id = 'trainer-uuid-here'
GROUP BY sync_status
ORDER BY count DESC;
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '🎉 Google Calendar Sync Setup Complete!' as message;
SELECT '📅 Sessions table ready for calendar integration' as status;
SELECT '✅ Run verification queries above to confirm' as next_step;
