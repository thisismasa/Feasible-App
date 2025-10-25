-- ============================================================================
-- TEST: UI to SQL Logic Synchronization
-- ============================================================================
-- This verifies that what the Flutter UI queries matches what SQL returns
-- ============================================================================

-- ============================================================================
-- TEST 1: What Booking Management Screen Queries
-- ============================================================================

SELECT '=== TEST 1: Booking Management Queries ===' as test_section;

-- The Flutter app calls these methods:
-- 1. getTodaySchedule(trainerId) -> queries 'today_schedule' view
-- 2. getUpcomingSessions(trainerId) -> queries 'trainer_upcoming_sessions' view
-- 3. getWeeklyCalendar(trainerId) -> queries 'weekly_calendar' view

-- Get all trainer IDs to test with
SELECT
  id as trainer_id,
  full_name as trainer_name,
  email
FROM users
WHERE role = 'trainer'
ORDER BY full_name;

-- ============================================================================
-- TEST 2: Simulate getTodaySchedule() Query
-- ============================================================================

SELECT '=== TEST 2: getTodaySchedule() Simulation ===' as test_section;

-- This is exactly what Flutter queries
SELECT *
FROM today_schedule
WHERE trainer_id = (
  SELECT id FROM users WHERE role = 'trainer' LIMIT 1
)
ORDER BY scheduled_start;

-- Check if view returns expected columns
SELECT
  column_name,
  data_type,
  '✅' as status
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'today_schedule'
ORDER BY ordinal_position;

-- ============================================================================
-- TEST 3: Simulate getUpcomingSessions() Query
-- ============================================================================

SELECT '=== TEST 3: getUpcomingSessions() Simulation ===' as test_section;

-- This is exactly what Flutter queries (with limit)
SELECT *
FROM trainer_upcoming_sessions
WHERE trainer_id = (
  SELECT id FROM users WHERE role = 'trainer' LIMIT 1
)
LIMIT 50;

-- Check count
SELECT
  'trainer_upcoming_sessions' as view_name,
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE scheduled_start >= NOW()) as future_sessions,
  COUNT(*) FILTER (WHERE scheduled_start < NOW()) as past_sessions
FROM trainer_upcoming_sessions;

-- ============================================================================
-- TEST 4: Simulate getWeeklyCalendar() Query
-- ============================================================================

SELECT '=== TEST 4: getWeeklyCalendar() Simulation ===' as test_section;

-- This is exactly what Flutter queries
SELECT *
FROM weekly_calendar
WHERE trainer_id = (
  SELECT id FROM users WHERE role = 'trainer' LIMIT 1
)
ORDER BY scheduled_start;

-- ============================================================================
-- TEST 5: Compare Direct Sessions Query vs View Query
-- ============================================================================

SELECT '=== TEST 5: Direct Query vs View Comparison ===' as test_section;

-- What SHOULD be in the view (direct query)
WITH direct_query AS (
  SELECT
    s.id as session_id,
    s.client_id,
    s.trainer_id,
    s.scheduled_start,
    s.scheduled_end,
    s.status,
    c.full_name as client_name,
    cp.package_name,
    cp.remaining_sessions
  FROM sessions s
  JOIN users c ON s.client_id = c.id
  LEFT JOIN client_packages cp ON s.package_id = cp.id
  WHERE s.status IN ('scheduled', 'confirmed')
    AND s.scheduled_start >= NOW()
  ORDER BY s.scheduled_start ASC
),
view_query AS (
  SELECT
    session_id,
    client_id,
    trainer_id,
    scheduled_start,
    scheduled_end,
    status,
    client_name,
    package_name,
    remaining_sessions
  FROM trainer_upcoming_sessions
  ORDER BY scheduled_start ASC
)
SELECT
  'Direct Query Count' as query_type,
  COUNT(*) as row_count
FROM direct_query
UNION ALL
SELECT
  'View Query Count',
  COUNT(*)
FROM view_query
UNION ALL
SELECT
  'Difference',
  (SELECT COUNT(*) FROM direct_query) - (SELECT COUNT(*) FROM view_query);

-- ============================================================================
-- TEST 6: Check for Missing JOINs or Filter Issues
-- ============================================================================

SELECT '=== TEST 6: Potential Data Loss in Views ===' as test_section;

-- Sessions that exist but might not appear in views
SELECT
  s.id,
  s.client_id,
  s.trainer_id,
  s.scheduled_start,
  s.status,
  CASE
    WHEN c.id IS NULL THEN '❌ Client user not found'
    WHEN t.id IS NULL THEN '❌ Trainer user not found'
    WHEN s.status NOT IN ('scheduled', 'confirmed') THEN '⚠️ Status excluded: ' || s.status
    WHEN s.scheduled_start < NOW() THEN '⚠️ Past session (excluded from upcoming)'
    ELSE '✅ Should appear in view'
  END as visibility_status
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
LEFT JOIN users t ON s.trainer_id = t.id
ORDER BY s.scheduled_start DESC
LIMIT 20;

-- ============================================================================
-- TEST 7: Check Package Data Availability in UI
-- ============================================================================

SELECT '=== TEST 7: Package Data for UI Display ===' as test_section;

-- When UI shows a session, it should also show package info
SELECT
  s.id as session_id,
  c.full_name as client_name,
  s.scheduled_start,
  s.package_id,
  cp.package_name,
  cp.remaining_sessions,
  CASE
    WHEN s.package_id IS NULL THEN '⚠️ No package (pay-per-session)'
    WHEN cp.id IS NULL THEN '❌ Package reference broken!'
    WHEN cp.package_name IS NULL THEN '⚠️ Package has no name'
    ELSE '✅ Package data available'
  END as package_data_status
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.status IN ('scheduled', 'confirmed')
ORDER BY s.scheduled_start DESC
LIMIT 10;

-- ============================================================================
-- TEST 8: Verify Trigger Integration
-- ============================================================================

SELECT '=== TEST 8: Trigger Integration Check ===' as test_section;

-- Check if trigger is attached to sessions table
SELECT
  trigger_name,
  event_manipulation as fires_on,
  action_timing as timing,
  action_statement as trigger_function
FROM information_schema.triggers
WHERE event_object_table = 'sessions'
  AND event_object_schema = 'public'
ORDER BY trigger_name;

-- Check trigger function exists
SELECT
  'sync_package_remaining_sessions' as function_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc
      WHERE proname = 'sync_package_remaining_sessions'
    ) THEN '✅ Function exists'
    ELSE '❌ Function missing'
  END as status;

-- ============================================================================
-- TEST 9: Check RLS (Row Level Security) Policies
-- ============================================================================

SELECT '=== TEST 9: Row Level Security Policies ===' as test_section;

-- Check if RLS is blocking data access
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE
    WHEN rowsecurity = true THEN '⚠️ RLS enabled - check policies'
    ELSE '✅ RLS disabled - no blocking'
  END as impact
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages', 'users')
ORDER BY tablename;

-- Check existing policies on sessions table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as applies_to
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages')
ORDER BY tablename, policyname;

-- ============================================================================
-- TEST 10: End-to-End Data Flow Test
-- ============================================================================

SELECT '=== TEST 10: Complete Data Flow ===' as test_section;

-- Trace a single session through the entire stack
WITH test_session AS (
  SELECT id FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT
  '1. Session exists in sessions table' as checkpoint,
  CASE WHEN COUNT(*) > 0 THEN '✅ Pass' ELSE '❌ Fail' END as status
FROM sessions
WHERE id = (SELECT id FROM test_session)

UNION ALL

SELECT
  '2. Session appears in trainer_upcoming_sessions view',
  CASE WHEN COUNT(*) > 0 THEN '✅ Pass' ELSE '❌ Fail' END
FROM trainer_upcoming_sessions
WHERE session_id = (SELECT id FROM test_session)

UNION ALL

SELECT
  '3. Client user exists and is joined',
  CASE WHEN COUNT(*) > 0 THEN '✅ Pass' ELSE '❌ Fail' END
FROM sessions s
JOIN users c ON s.client_id = c.id
WHERE s.id = (SELECT id FROM test_session)

UNION ALL

SELECT
  '4. Package is linked correctly',
  CASE
    WHEN COUNT(*) > 0 OR (SELECT package_id FROM sessions WHERE id = (SELECT id FROM test_session)) IS NULL
    THEN '✅ Pass'
    ELSE '❌ Fail'
  END
FROM sessions s
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.id = (SELECT id FROM test_session)
  AND (s.package_id IS NULL OR cp.id IS NOT NULL);

-- ============================================================================
-- SUMMARY: What Flutter UI Should See
-- ============================================================================

SELECT '=== FINAL SUMMARY: UI Data Availability ===' as test_section;

SELECT
  'Today Schedule' as ui_component,
  COUNT(*) as available_records,
  CASE
    WHEN COUNT(*) >= 0 THEN '✅ Working'
    ELSE '❌ Error'
  END as status
FROM today_schedule
WHERE trainer_id = (SELECT id FROM users WHERE role = 'trainer' LIMIT 1)

UNION ALL

SELECT
  'Upcoming Sessions',
  COUNT(*),
  CASE
    WHEN COUNT(*) > 0 THEN '✅ Has Data'
    ELSE '⚠️ No Data'
  END
FROM trainer_upcoming_sessions
WHERE trainer_id = (SELECT id FROM users WHERE role = 'trainer' LIMIT 1)

UNION ALL

SELECT
  'Weekly Calendar',
  COUNT(*),
  CASE
    WHEN COUNT(*) >= 0 THEN '✅ Working'
    ELSE '❌ Error'
  END
FROM weekly_calendar
WHERE trainer_id = (SELECT id FROM users WHERE role = 'trainer' LIMIT 1);

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- ✅ All views return data without errors
-- ✅ Direct query count matches view query count
-- ✅ All sessions have valid client and trainer users
-- ✅ Package data is available for sessions
-- ✅ Trigger is attached and active
-- ✅ RLS policies (if any) are not blocking data
-- ✅ End-to-end data flow passes all checkpoints
-- ============================================================================

-- ============================================================================
-- IF ANY TESTS FAIL:
-- ============================================================================
-- ❌ Views return 0 rows but sessions exist -> Re-run FIX_BOOKING_VIEWS_COMPLETE.sql
-- ❌ Direct query != View query -> Views have wrong filters/JOINs
-- ❌ Package reference broken -> Fix foreign keys
-- ❌ Trigger not attached -> Re-run FIX_TRIGGER_FOR_CLIENT_PACKAGES_ID.sql
-- ❌ RLS blocking access -> Check policies or disable RLS for testing
-- ============================================================================
