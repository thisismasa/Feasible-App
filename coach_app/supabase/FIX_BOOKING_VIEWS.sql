-- ============================================================================
-- FIX BOOKING MANAGEMENT VIEWS - Handle NULL values
-- ============================================================================

-- Fix VIEW 1: trainer_upcoming_sessions with COALESCE for NULLs
CREATE OR REPLACE VIEW trainer_upcoming_sessions AS
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  COALESCE(s.session_type, 'in_person') as session_type,
  COALESCE(s.location, 'TBD') as location,
  s.status,
  COALESCE(s.client_notes, '') as client_notes,
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
  COALESCE(c.email, '') as client_email,
  c.avatar_url as client_avatar,

  -- Trainer information
  t.id as trainer_id,
  t.full_name as trainer_name,

  -- Package information
  p.id as package_id,
  COALESCE(p.name, 'Package') as package_name,
  p.sessions as package_total_sessions,

  -- Session counts for this package
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'completed') as sessions_completed,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'scheduled') as sessions_scheduled,

  -- Buffer times
  s.buffer_start,
  s.buffer_end,

  -- Conflict indicators
  COALESCE(s.has_conflicts, FALSE) as has_conflicts,
  COALESCE(s.validation_passed, TRUE) as validation_passed

FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
WHERE s.status IN ('scheduled', 'confirmed')
  AND s.scheduled_start >= NOW()
ORDER BY s.scheduled_start ASC;

COMMENT ON VIEW trainer_upcoming_sessions IS 'Complete view of upcoming sessions with client and package details (NULL-safe)';

-- Fix VIEW 2: today_schedule
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

COMMENT ON VIEW today_schedule IS 'Today''s sessions for quick daily planning (NULL-safe)';

-- Fix VIEW 3: weekly_calendar
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

COMMENT ON VIEW weekly_calendar IS '7-day calendar view for weekly planning (NULL-safe)';

-- Verify the fix
SELECT
  '✅ Views updated' as status,
  COUNT(*) as session_count
FROM trainer_upcoming_sessions
WHERE trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921';
