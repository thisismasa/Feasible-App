-- ============================================================================
-- FINAL UI TEST: Verify what Booking Management will display
-- ============================================================================

-- ============================================================================
-- TEST 1: What "Upcoming" tab will show
-- ============================================================================
SELECT
  'UPCOMING TAB DATA' as test_name;

SELECT
  session_id,
  client_name,
  trainer_name,
  scheduled_start,
  scheduled_end,
  duration_minutes,
  status,
  session_type,
  location,
  package_name,
  remaining_sessions
FROM trainer_upcoming_sessions
ORDER BY scheduled_start ASC;

-- ============================================================================
-- TEST 2: What "Today" tab will show
-- ============================================================================
SELECT
  'TODAY TAB DATA' as test_name;

SELECT
  session_id,
  client_name,
  trainer_name,
  scheduled_start,
  scheduled_end,
  duration_minutes,
  status,
  session_type,
  location,
  package_name
FROM today_schedule
ORDER BY scheduled_start ASC;

-- ============================================================================
-- TEST 3: Package session counts
-- ============================================================================
SELECT
  'PACKAGE COUNTS' as test_name;

SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  c.full_name as client_name,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status = 'scheduled'
  ) as actual_booked_sessions,
  CASE
    WHEN (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status = 'scheduled') = cp.used_sessions
    THEN '✅ SYNCED'
    ELSE '⚠️ OUT OF SYNC'
  END as sync_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%';

-- ============================================================================
-- TEST 4: Verify trigger will work on NEXT booking
-- ============================================================================
SELECT
  'TRIGGER READINESS' as test_name;

SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  event_object_table,
  'ACTIVE' as status
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions';

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- TEST 1: Should show 8 rows (all Nuttapon's upcoming sessions)
--         This is what "Upcoming (8)" tab will display
--
-- TEST 2: Should show 2 rows (sessions scheduled for today)
--         This is what "Today (2)" tab will display
--
-- TEST 3: Should show:
--         - total_sessions = 10
--         - used_sessions = 8 (if trigger worked) OR 0 (if not yet synced)
--         - remaining_sessions = 2 (if synced) OR 10 (if not synced)
--         - actual_booked_sessions = 8
--         - sync_status = ✅ SYNCED or ⚠️ OUT OF SYNC
--
-- TEST 4: Should show trigger is ACTIVE
-- ============================================================================

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 1. Go to Flutter app → Booking Management screen
-- 2. Click refresh button (top right)
-- 3. Should see:
--    - "Today (2)" tab
--    - "Upcoming (8)" tab
--    - "Weekly (3)" tab
-- 4. Click on "Upcoming" tab
-- 5. Should see list of 8 sessions with Nuttapon's name
-- 6. Click on any session to see details
-- ============================================================================
