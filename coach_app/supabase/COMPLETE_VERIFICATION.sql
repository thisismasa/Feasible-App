-- ============================================================================
-- COMPLETE END-TO-END VERIFICATION
-- Run this after fixing views to verify everything works
-- ============================================================================

-- ============================================================================
-- SECTION 1: VERIFY SESSIONS EXIST
-- ============================================================================
SELECT '=== SECTION 1: SESSIONS IN DATABASE ===' as section;

SELECT
  s.id as session_id,
  c.full_name as client_name,
  t.full_name as trainer_name,
  s.scheduled_start,
  s.status,
  s.package_id,
  cp.package_name,
  s.created_at
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY s.created_at DESC;

-- ============================================================================
-- SECTION 2: VERIFY PACKAGE COUNTS
-- ============================================================================
SELECT '=== SECTION 2: PACKAGE SESSION COUNTS ===' as section;

SELECT
  cp.id as package_id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.status,
  c.full_name as client_name,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status = 'scheduled'
  ) as actual_booked_sessions
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- SECTION 3: VERIFY TRIGGER IS WORKING
-- ============================================================================
SELECT '=== SECTION 3: TRIGGER STATUS ===' as section;

SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions';

-- ============================================================================
-- SECTION 4: VERIFY VIEWS ARE WORKING
-- ============================================================================
SELECT '=== SECTION 4: VIEW DATA COUNTS ===' as section;

SELECT
  'today_schedule' as view_name,
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE client_name ILIKE '%Nuttapon%') as nuttapon_rows
FROM today_schedule
UNION ALL
SELECT
  'trainer_upcoming_sessions',
  COUNT(*),
  COUNT(*) FILTER (WHERE client_name ILIKE '%Nuttapon%')
FROM trainer_upcoming_sessions
UNION ALL
SELECT
  'weekly_calendar',
  COUNT(*),
  COUNT(*) FILTER (WHERE client_name ILIKE '%Nuttapon%')
FROM weekly_calendar;

-- ============================================================================
-- SECTION 5: SHOW WHAT BOOKING MANAGEMENT WILL SEE
-- ============================================================================
SELECT '=== SECTION 5: UPCOMING SESSIONS (WHAT UI SEES) ===' as section;

SELECT
  session_id,
  client_name,
  trainer_name,
  scheduled_start,
  duration_minutes,
  status,
  session_type,
  location,
  package_name,
  remaining_sessions
FROM trainer_upcoming_sessions
ORDER BY scheduled_start ASC
LIMIT 10;

-- ============================================================================
-- SECTION 6: DATA CONSISTENCY CHECK
-- ============================================================================
SELECT '=== SECTION 6: DATA CONSISTENCY ===' as section;

SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (cp.used_sessions + cp.remaining_sessions) as calculated_total,
  CASE
    WHEN (cp.used_sessions + cp.remaining_sessions) = cp.total_sessions THEN '✅ CONSISTENT'
    ELSE '❌ MISMATCH!'
  END as consistency_check,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id AND s.status = 'scheduled'
  ) as actual_scheduled_sessions,
  CASE
    WHEN (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status = 'scheduled') = cp.used_sessions
    THEN '✅ MATCHES'
    ELSE '⚠️ DIFFERENT'
  END as session_count_match
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%';

-- ============================================================================
-- EXPECTED RESULTS SUMMARY
-- ============================================================================
--
-- SECTION 1: Should show all Nuttapon's booked sessions
--
-- SECTION 2: Should show:
--   - total_sessions = 10
--   - used_sessions = number of booked sessions (1, 2, etc.)
--   - remaining_sessions = 10 - used_sessions
--   - actual_booked_sessions = should match used_sessions
--
-- SECTION 3: Should show trigger exists with INSERT, UPDATE events
--
-- SECTION 4: Should show:
--   - today_schedule: 0 or more (depends if booking is today)
--   - trainer_upcoming_sessions: 1+ (your booked session(s))
--   - weekly_calendar: 0 or more (depends if booking is this week)
--
-- SECTION 5: Shows exactly what Booking Management UI will display
--   - Should list Nuttapon's session(s) with all details
--
-- SECTION 6: Validates data integrity:
--   - used + remaining should equal total
--   - actual scheduled sessions should match used_sessions
--
-- ============================================================================
