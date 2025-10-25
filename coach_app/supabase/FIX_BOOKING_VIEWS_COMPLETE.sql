-- ============================================================================
-- FIX: Recreate all booking management views with correct schema
-- Purpose: Fix views to show sessions in Booking Management UI
-- ============================================================================

-- Drop old views
DROP VIEW IF EXISTS today_schedule CASCADE;
DROP VIEW IF EXISTS trainer_upcoming_sessions CASCADE;
DROP VIEW IF EXISTS weekly_calendar CASCADE;

-- ============================================================================
-- VIEW 1: today_schedule - Shows today's sessions for a trainer
-- ============================================================================
CREATE OR REPLACE VIEW today_schedule AS
SELECT
  s.id as session_id,
  s.client_id,
  s.trainer_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.status,
  s.session_type,
  s.location,
  s.notes,
  c.full_name as client_name,
  c.email as client_email,
  c.phone as client_phone,
  t.full_name as trainer_name,
  cp.package_name,
  cp.id as client_package_id
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.status IN ('scheduled', 'confirmed')
  AND DATE(s.scheduled_start) = CURRENT_DATE;

-- ============================================================================
-- VIEW 2: trainer_upcoming_sessions - Shows all upcoming sessions
-- ============================================================================
CREATE OR REPLACE VIEW trainer_upcoming_sessions AS
SELECT
  s.id as session_id,
  s.client_id,
  s.trainer_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.status,
  s.session_type,
  s.location,
  s.notes,
  s.created_at,
  c.full_name as client_name,
  c.email as client_email,
  c.phone as client_phone,
  t.full_name as trainer_name,
  cp.package_name,
  cp.id as client_package_id,
  cp.remaining_sessions
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.status IN ('scheduled', 'confirmed')
  AND s.scheduled_start >= NOW()
ORDER BY s.scheduled_start ASC;

-- ============================================================================
-- VIEW 3: weekly_calendar - Shows this week's sessions
-- ============================================================================
CREATE OR REPLACE VIEW weekly_calendar AS
SELECT
  s.id as session_id,
  s.client_id,
  s.trainer_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.status,
  s.session_type,
  s.location,
  c.full_name as client_name,
  c.email as client_email,
  t.full_name as trainer_name,
  cp.package_name,
  DATE(s.scheduled_start) as session_date,
  TO_CHAR(s.scheduled_start, 'Day') as day_of_week,
  EXTRACT(DOW FROM s.scheduled_start) as day_number
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.status IN ('scheduled', 'confirmed')
  AND s.scheduled_start >= DATE_TRUNC('week', CURRENT_DATE)
  AND s.scheduled_start < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
ORDER BY s.scheduled_start ASC;

-- ============================================================================
-- Grant permissions to views
-- ============================================================================
GRANT SELECT ON today_schedule TO authenticated;
GRANT SELECT ON today_schedule TO anon;

GRANT SELECT ON trainer_upcoming_sessions TO authenticated;
GRANT SELECT ON trainer_upcoming_sessions TO anon;

GRANT SELECT ON weekly_calendar TO authenticated;
GRANT SELECT ON weekly_calendar TO anon;

-- ============================================================================
-- Verify views were created and return data
-- ============================================================================
DO $$
DECLARE
  v_today_count INTEGER;
  v_upcoming_count INTEGER;
  v_weekly_count INTEGER;
BEGIN
  -- Count rows in each view
  SELECT COUNT(*) INTO v_today_count FROM today_schedule;
  SELECT COUNT(*) INTO v_upcoming_count FROM trainer_upcoming_sessions;
  SELECT COUNT(*) INTO v_weekly_count FROM weekly_calendar;

  RAISE NOTICE '✅ Views recreated successfully!';
  RAISE NOTICE 'today_schedule: % rows', v_today_count;
  RAISE NOTICE 'trainer_upcoming_sessions: % rows', v_upcoming_count;
  RAISE NOTICE 'weekly_calendar: % rows', v_weekly_count;

  IF v_upcoming_count > 0 THEN
    RAISE NOTICE '✅ SUCCESS: trainer_upcoming_sessions has data!';
  ELSE
    RAISE WARNING '⚠️ trainer_upcoming_sessions is empty - check if sessions exist with future dates';
  END IF;
END $$;

-- ============================================================================
-- Test query: Verify Nuttapon's sessions now appear
-- ============================================================================
SELECT
  'today_schedule' as view_name,
  COUNT(*) as nuttapon_sessions
FROM today_schedule
WHERE client_name ILIKE '%Nuttapon%'
UNION ALL
SELECT
  'trainer_upcoming_sessions',
  COUNT(*)
FROM trainer_upcoming_sessions
WHERE client_name ILIKE '%Nuttapon%'
UNION ALL
SELECT
  'weekly_calendar',
  COUNT(*)
FROM weekly_calendar
WHERE client_name ILIKE '%Nuttapon%';

-- ============================================================================
-- WHAT WAS FIXED:
-- ============================================================================
-- 1. Removed any filters that might exclude sessions
-- 2. Used LEFT JOIN for client_packages (in case package_id is NULL)
-- 3. Simplified date filters
-- 4. Made sure all necessary columns are included
-- 5. Added proper permissions
-- ============================================================================

-- ============================================================================
-- AFTER RUNNING THIS:
-- ============================================================================
-- 1. Views should show Nuttapon's session(s)
-- 2. Go to Flutter app → Booking Management
-- 3. Click refresh button
-- 4. Should see "Upcoming (X)" where X > 0
-- 5. Sessions should appear in the list
-- ============================================================================
