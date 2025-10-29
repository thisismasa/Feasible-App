-- ============================================================================
-- ENHANCED CALENDAR SYNC - Alternative Solutions
-- ============================================================================
-- This provides multiple ways to get PT sessions into Google Calendar:
-- 1. Direct API sync (via Flutter app)
-- 2. Calendar file download (.ics)
-- 3. Calendar feed URL (subscribe)
-- 4. Webhook notifications
-- ============================================================================

-- ============================================================================
-- STEP 1: Create function to generate iCalendar (.ics) format
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_ics_for_session(p_session_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_session RECORD;
  v_client_name TEXT;
  v_ics TEXT;
  v_start TEXT;
  v_end TEXT;
  v_created TEXT;
BEGIN
  -- Get session details with client info
  SELECT
    s.*,
    c.full_name as client_name,
    c.email as client_email
  INTO v_session
  FROM sessions s
  LEFT JOIN users c ON s.client_id = c.id
  WHERE s.id = p_session_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Format dates for iCalendar (YYYYMMDDTHHmmssZ)
  v_start := TO_CHAR(v_session.scheduled_start AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"');
  v_end := TO_CHAR(v_session.scheduled_end AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"');
  v_created := TO_CHAR(v_session.created_at AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"');

  -- Generate iCalendar format
  v_ics := 'BEGIN:VCALENDAR' || E'\n' ||
           'VERSION:2.0' || E'\n' ||
           'PRODID:-//PT Coach//Session Booking//EN' || E'\n' ||
           'BEGIN:VEVENT' || E'\n' ||
           'UID:' || p_session_id || '@pt-coach.app' || E'\n' ||
           'DTSTAMP:' || v_created || E'\n' ||
           'DTSTART:' || v_start || E'\n' ||
           'DTEND:' || v_end || E'\n' ||
           'SUMMARY:PT Session - ' || COALESCE(v_session.client_name, 'Client') || E'\n' ||
           'DESCRIPTION:Personal Training Session\\n' ||
             CASE WHEN v_session.notes IS NOT NULL
               THEN 'Notes: ' || REPLACE(v_session.notes, E'\n', '\\n')
               ELSE ''
             END || E'\n' ||
           CASE WHEN v_session.location IS NOT NULL
             THEN 'LOCATION:' || v_session.location || E'\n'
             ELSE ''
           END ||
           'STATUS:' || CASE v_session.status
             WHEN 'scheduled' THEN 'CONFIRMED'
             WHEN 'confirmed' THEN 'CONFIRMED'
             WHEN 'cancelled' THEN 'CANCELLED'
             ELSE 'TENTATIVE'
           END || E'\n' ||
           'BEGIN:VALARM' || E'\n' ||
           'TRIGGER:-PT30M' || E'\n' ||
           'DESCRIPTION:PT Session in 30 minutes' || E'\n' ||
           'ACTION:DISPLAY' || E'\n' ||
           'END:VALARM' || E'\n' ||
           'END:VEVENT' || E'\n' ||
           'END:VCALENDAR';

  RETURN v_ics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION generate_ics_for_session IS 'Generate .ics calendar file for a session';

-- ============================================================================
-- STEP 2: Create function to generate calendar feed for a trainer
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_calendar_feed(p_trainer_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_ics TEXT;
  v_session RECORD;
  v_events TEXT := '';
  v_start TEXT;
  v_end TEXT;
BEGIN
  -- Generate iCalendar feed with all upcoming sessions
  FOR v_session IN
    SELECT
      s.id,
      s.scheduled_start,
      s.scheduled_end,
      s.status,
      s.location,
      s.notes,
      s.created_at,
      c.full_name as client_name
    FROM sessions s
    LEFT JOIN users c ON s.client_id = c.id
    WHERE s.trainer_id = p_trainer_id
      AND s.status IN ('scheduled', 'confirmed')
      AND s.scheduled_start >= NOW()
    ORDER BY s.scheduled_start
  LOOP
    -- Format dates
    v_start := TO_CHAR(v_session.scheduled_start AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"');
    v_end := TO_CHAR(v_session.scheduled_end AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"');

    -- Add event to feed
    v_events := v_events ||
      'BEGIN:VEVENT' || E'\n' ||
      'UID:' || v_session.id || '@pt-coach.app' || E'\n' ||
      'DTSTAMP:' || TO_CHAR(v_session.created_at AT TIME ZONE 'UTC', 'YYYYMMDD"T"HH24MISS"Z"') || E'\n' ||
      'DTSTART:' || v_start || E'\n' ||
      'DTEND:' || v_end || E'\n' ||
      'SUMMARY:PT Session - ' || COALESCE(v_session.client_name, 'Client') || E'\n' ||
      CASE WHEN v_session.location IS NOT NULL
        THEN 'LOCATION:' || v_session.location || E'\n'
        ELSE ''
      END ||
      'STATUS:CONFIRMED' || E'\n' ||
      'END:VEVENT' || E'\n';
  END LOOP;

  -- Wrap in VCALENDAR
  v_ics := 'BEGIN:VCALENDAR' || E'\n' ||
           'VERSION:2.0' || E'\n' ||
           'PRODID:-//PT Coach//Calendar Feed//EN' || E'\n' ||
           'CALSCALE:GREGORIAN' || E'\n' ||
           'METHOD:PUBLISH' || E'\n' ||
           'X-WR-CALNAME:PT Coach Sessions' || E'\n' ||
           'X-WR-TIMEZONE:UTC' || E'\n' ||
           v_events ||
           'END:VCALENDAR';

  RETURN v_ics;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION generate_calendar_feed IS 'Generate .ics calendar feed for all trainer sessions';

-- ============================================================================
-- STEP 3: Create view for calendar-ready sessions
-- ============================================================================

CREATE OR REPLACE VIEW calendar_ready_sessions AS
SELECT
  s.id as session_id,
  s.trainer_id,
  s.client_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.session_type,
  s.location,
  s.notes,
  s.google_calendar_event_id,
  c.full_name as client_name,
  c.email as client_email,
  t.full_name as trainer_name,
  t.email as trainer_email,
  CASE
    WHEN s.google_calendar_event_id IS NOT NULL THEN '✅ Synced'
    WHEN s.status IN ('scheduled', 'confirmed') AND s.scheduled_start >= NOW() THEN '⏳ Needs Sync'
    WHEN s.status = 'cancelled' THEN '🚫 Cancelled'
    ELSE '⏰ Past'
  END as sync_status,
  -- Generate direct .ics download URL (you'll need to expose this via Edge Function)
  '/api/calendar/download/' || s.id || '.ics' as download_url,
  -- Calendar details for API
  jsonb_build_object(
    'summary', 'PT Session - ' || COALESCE(c.full_name, 'Client'),
    'start', s.scheduled_start,
    'end', s.scheduled_end,
    'location', s.location,
    'description', COALESCE(s.notes, 'Personal training session'),
    'attendees', jsonb_build_array(
      jsonb_build_object('email', c.email, 'name', c.full_name)
    )
  ) as calendar_event_data
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
LEFT JOIN users t ON s.trainer_id = t.id
WHERE s.status IN ('scheduled', 'confirmed')
ORDER BY s.scheduled_start;

COMMENT ON VIEW calendar_ready_sessions IS 'Sessions ready for calendar sync with all necessary data';

-- ============================================================================
-- STEP 4: Create webhook notification table
-- ============================================================================

CREATE TABLE IF NOT EXISTS calendar_sync_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  webhook_type TEXT NOT NULL, -- 'created', 'updated', 'cancelled'
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_webhook_type CHECK (webhook_type IN ('created', 'updated', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_calendar_webhooks_processed ON calendar_sync_webhooks(processed, created_at);
CREATE INDEX IF NOT EXISTS idx_calendar_webhooks_session ON calendar_sync_webhooks(session_id);

COMMENT ON TABLE calendar_sync_webhooks IS 'Queue for calendar sync webhook notifications';

-- ============================================================================
-- STEP 5: Create trigger to automatically queue calendar syncs
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_calendar_sync_webhook()
RETURNS TRIGGER AS $$
BEGIN
  -- When a new session is created
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO calendar_sync_webhooks (session_id, webhook_type, payload)
    VALUES (
      NEW.id,
      'created',
      jsonb_build_object(
        'session_id', NEW.id,
        'client_id', NEW.client_id,
        'trainer_id', NEW.trainer_id,
        'scheduled_start', NEW.scheduled_start,
        'scheduled_end', NEW.scheduled_end,
        'location', NEW.location,
        'notes', NEW.notes
      )
    );

  -- When a session is cancelled
  ELSIF (TG_OP = 'UPDATE' AND OLD.status != 'cancelled' AND NEW.status = 'cancelled') THEN
    -- Only queue if it was previously synced
    IF NEW.google_calendar_event_id IS NOT NULL THEN
      INSERT INTO calendar_sync_webhooks (session_id, webhook_type, payload)
      VALUES (
        NEW.id,
        'cancelled',
        jsonb_build_object(
          'session_id', NEW.id,
          'google_calendar_event_id', NEW.google_calendar_event_id
        )
      );
    END IF;

  -- When session time is updated
  ELSIF (TG_OP = 'UPDATE' AND (
    OLD.scheduled_start != NEW.scheduled_start OR
    OLD.scheduled_end != NEW.scheduled_end OR
    OLD.location != NEW.location
  )) THEN
    IF NEW.google_calendar_event_id IS NOT NULL THEN
      INSERT INTO calendar_sync_webhooks (session_id, webhook_type, payload)
      VALUES (
        NEW.id,
        'updated',
        jsonb_build_object(
          'session_id', NEW.id,
          'google_calendar_event_id', NEW.google_calendar_event_id,
          'scheduled_start', NEW.scheduled_start,
          'scheduled_end', NEW.scheduled_end,
          'location', NEW.location
        )
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS calendar_sync_webhook_trigger ON sessions;

-- Create trigger
CREATE TRIGGER calendar_sync_webhook_trigger
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_calendar_sync_webhook();

COMMENT ON FUNCTION trigger_calendar_sync_webhook IS 'Automatically queue calendar sync webhooks';

-- ============================================================================
-- STEP 6: Verification and testing
-- ============================================================================

-- Test iCalendar generation for latest session
SELECT
  'Test .ics generation:' as test,
  generate_ics_for_session(id) as ics_content
FROM sessions
ORDER BY created_at DESC
LIMIT 1;

-- Show calendar-ready sessions
SELECT * FROM calendar_ready_sessions LIMIT 5;

-- Show pending webhooks
SELECT * FROM calendar_sync_webhooks
WHERE processed = FALSE
ORDER BY created_at DESC;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '🎉 Enhanced Calendar Sync Setup Complete!' as message;
SELECT '📅 Multiple sync methods now available:' as info;
SELECT '   1. Direct Google Calendar API sync (via app)' as method_1;
SELECT '   2. Downloadable .ics files for each session' as method_2;
SELECT '   3. Calendar feed subscription URL' as method_3;
SELECT '   4. Automatic webhook queue for background sync' as method_4;
