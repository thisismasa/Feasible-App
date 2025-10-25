-- ============================================================================
-- BOOKING MANAGEMENT VIEWS & FUNCTIONS
-- ============================================================================
-- Provides comprehensive views for trainers to manage all bookings
-- Features: Upcoming sessions, today's schedule, weekly calendar, client history
-- ============================================================================

-- VIEW 1: Upcoming Sessions Dashboard
-- Shows all scheduled sessions with client info, package details, and status
-- ============================================================================

CREATE OR REPLACE VIEW trainer_upcoming_sessions AS
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.session_type,
  s.location,
  s.status,
  s.client_notes,
  s.created_at as booked_at,

  -- Time calculations
  EXTRACT(EPOCH FROM (s.scheduled_start - NOW())) / 60 as minutes_until_session,
  DATE(s.scheduled_start) as session_date,
  TO_CHAR(s.scheduled_start, 'HH24:MI') as start_time,
  TO_CHAR(s.scheduled_end, 'HH24:MI') as end_time,
  TO_CHAR(s.scheduled_start, 'Day') as day_of_week,

  -- Client information
  c.id as client_id,
  c.full_name as client_name,
  c.email as client_email,
  c.avatar_url as client_avatar,

  -- Trainer information
  t.id as trainer_id,
  t.full_name as trainer_name,

  -- Package information
  p.id as package_id,
  p.name as package_name,
  p.sessions as package_total_sessions,

  -- Session counts for this package
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'completed') as sessions_completed,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'scheduled') as sessions_scheduled,

  -- Buffer times
  s.buffer_start,
  s.buffer_end,

  -- Conflict indicators
  s.has_conflicts,
  s.validation_passed

FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
WHERE s.status IN ('scheduled', 'confirmed')
  AND s.scheduled_start >= NOW()
ORDER BY s.scheduled_start ASC;

COMMENT ON VIEW trainer_upcoming_sessions IS 'Complete view of upcoming sessions with client and package details';

-- VIEW 2: Today's Schedule
-- Quick view of today's sessions for trainers
-- ============================================================================

CREATE OR REPLACE VIEW today_schedule AS
SELECT
  session_id,
  scheduled_start,
  scheduled_end,
  start_time,
  end_time,
  duration_minutes,
  session_type,
  location,
  client_id,
  client_name,
  client_email,
  client_avatar,
  trainer_id,
  trainer_name,
  package_name,
  client_notes,
  status,
  minutes_until_session
FROM trainer_upcoming_sessions
WHERE session_date = CURRENT_DATE
ORDER BY scheduled_start ASC;

COMMENT ON VIEW today_schedule IS 'Today''s sessions for quick daily planning';

-- VIEW 3: Weekly Calendar View
-- Shows sessions grouped by day for weekly planning
-- ============================================================================

CREATE OR REPLACE VIEW weekly_calendar AS
SELECT
  session_id,
  session_date,
  day_of_week,
  start_time,
  end_time,
  duration_minutes,
  session_type,
  client_name,
  client_id,
  trainer_id,
  package_name,
  status,
  location
FROM trainer_upcoming_sessions
WHERE session_date >= CURRENT_DATE
  AND session_date <= CURRENT_DATE + INTERVAL '7 days'
ORDER BY session_date, scheduled_start;

COMMENT ON VIEW weekly_calendar IS '7-day calendar view for weekly planning';

-- VIEW 4: Client Session History
-- Complete history of all sessions with a client
-- ============================================================================

CREATE OR REPLACE VIEW client_session_history AS
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.session_type,
  s.location,
  s.status,
  s.client_notes,
  s.cancellation_reason,
  s.created_at as booked_at,

  -- Time info
  DATE(s.scheduled_start) as session_date,
  TO_CHAR(s.scheduled_start, 'HH24:MI') as start_time,

  -- Client info
  c.id as client_id,
  c.full_name as client_name,
  c.email as client_email,

  -- Trainer info
  t.id as trainer_id,
  t.full_name as trainer_name,

  -- Package info
  p.id as package_id,
  p.name as package_name,

  -- Status indicators
  CASE
    WHEN s.status = 'completed' THEN '✅ Completed'
    WHEN s.status = 'scheduled' THEN '📅 Scheduled'
    WHEN s.status = 'cancelled' THEN '❌ Cancelled'
    WHEN s.status = 'no_show' THEN '⚠️ No Show'
    ELSE s.status
  END as status_display

FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
ORDER BY s.scheduled_start DESC;

COMMENT ON VIEW client_session_history IS 'Complete session history for all clients';

-- FUNCTION: Get Trainer's Sessions for Date Range
-- Returns sessions for a trainer within specific dates
-- ============================================================================

CREATE OR REPLACE FUNCTION get_trainer_sessions_range(
  p_trainer_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_status TEXT[] DEFAULT ARRAY['scheduled', 'confirmed']
)
RETURNS TABLE (
  session_id UUID,
  scheduled_start TIMESTAMPTZ,
  scheduled_end TIMESTAMPTZ,
  duration_minutes INTEGER,
  session_type TEXT,
  location TEXT,
  status TEXT,
  client_id UUID,
  client_name TEXT,
  client_email TEXT,
  package_name TEXT,
  client_notes TEXT,
  minutes_until_session NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.scheduled_start,
    s.scheduled_end,
    s.duration_minutes,
    s.session_type,
    s.location,
    s.status,
    c.id,
    c.full_name,
    c.email,
    p.name,
    s.client_notes,
    EXTRACT(EPOCH FROM (s.scheduled_start - NOW())) / 60
  FROM sessions s
  JOIN users c ON s.client_id = c.id
  JOIN packages p ON s.package_id = p.id
  WHERE s.trainer_id = p_trainer_id
    AND s.scheduled_start >= p_start_date
    AND s.scheduled_start <= p_end_date
    AND s.status = ANY(p_status)
  ORDER BY s.scheduled_start ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_trainer_sessions_range IS 'Get trainer sessions for specific date range with filters';

-- FUNCTION: Get Session Details
-- Returns complete details for a specific session
-- ============================================================================

CREATE OR REPLACE FUNCTION get_session_details(p_session_id UUID)
RETURNS TABLE (
  session_id UUID,
  scheduled_start TIMESTAMPTZ,
  scheduled_end TIMESTAMPTZ,
  duration_minutes INTEGER,
  session_type TEXT,
  location TEXT,
  status TEXT,
  client_notes TEXT,
  cancellation_reason TEXT,
  buffer_start TIMESTAMPTZ,
  buffer_end TIMESTAMPTZ,
  client_id UUID,
  client_name TEXT,
  client_email TEXT,
  client_phone TEXT,
  trainer_id UUID,
  trainer_name TEXT,
  package_id UUID,
  package_name TEXT,
  package_sessions INTEGER,
  sessions_completed BIGINT,
  sessions_scheduled BIGINT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.scheduled_start,
    s.scheduled_end,
    s.duration_minutes,
    s.session_type,
    s.location,
    s.status,
    s.client_notes,
    s.cancellation_reason,
    s.buffer_start,
    s.buffer_end,
    c.id,
    c.full_name,
    c.email,
    c.phone,
    t.id,
    t.full_name,
    p.id,
    p.name,
    p.sessions,
    (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'completed'),
    (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'scheduled'),
    s.created_at
  FROM sessions s
  JOIN users c ON s.client_id = c.id
  JOIN users t ON s.trainer_id = t.id
  JOIN packages p ON s.package_id = p.id
  WHERE s.id = p_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_session_details IS 'Get complete details for a specific session';

-- FUNCTION: Cancel Session with Reason
-- Cancels a session and records the reason
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_session_with_reason(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_session RECORD;
BEGIN
  -- Get session details
  SELECT * INTO v_session
  FROM sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Session not found'
    );
  END IF;

  -- Check if already cancelled
  IF v_session.status = 'cancelled' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Session already cancelled'
    );
  END IF;

  -- Update session status
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = p_cancellation_reason,
    updated_at = NOW()
  WHERE id = p_session_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Session cancelled successfully',
    'session_id', p_session_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cancel_session_with_reason IS 'Cancel a session with reason tracking';

-- FUNCTION: Reschedule Session
-- Moves a session to a new time slot
-- ============================================================================

CREATE OR REPLACE FUNCTION reschedule_session(
  p_session_id UUID,
  p_new_start TIMESTAMPTZ,
  p_new_duration_minutes INTEGER DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_session RECORD;
  v_new_end TIMESTAMPTZ;
BEGIN
  -- Get current session
  SELECT * INTO v_session
  FROM sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Session not found'
    );
  END IF;

  -- Calculate new end time
  IF p_new_duration_minutes IS NOT NULL THEN
    v_new_end := p_new_start + (p_new_duration_minutes || ' minutes')::INTERVAL;
  ELSE
    v_new_end := p_new_start + (v_session.duration_minutes || ' minutes')::INTERVAL;
  END IF;

  -- Check for conflicts
  IF EXISTS (
    SELECT 1 FROM sessions
    WHERE trainer_id = v_session.trainer_id
      AND id != p_session_id
      AND status IN ('scheduled', 'confirmed')
      AND tstzrange(scheduled_start, scheduled_end, '[]') &&
          tstzrange(p_new_start, v_new_end, '[]')
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Time slot conflicts with another session'
    );
  END IF;

  -- Update session
  UPDATE sessions
  SET
    scheduled_start = p_new_start,
    scheduled_end = v_new_end,
    duration_minutes = COALESCE(p_new_duration_minutes, duration_minutes),
    updated_at = NOW()
  WHERE id = p_session_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Session rescheduled successfully',
    'session_id', p_session_id,
    'new_start', p_new_start,
    'new_end', v_new_end
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION reschedule_session IS 'Reschedule a session to a new time with conflict checking';

-- Grant permissions
GRANT SELECT ON trainer_upcoming_sessions TO authenticated;
GRANT SELECT ON today_schedule TO authenticated;
GRANT SELECT ON weekly_calendar TO authenticated;
GRANT SELECT ON client_session_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_trainer_sessions_range TO authenticated;
GRANT EXECUTE ON FUNCTION get_session_details TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_reason TO authenticated;
GRANT EXECUTE ON FUNCTION reschedule_session TO authenticated;
