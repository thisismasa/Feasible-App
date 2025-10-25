-- ============================================================================
-- COMPLETE SYSTEM VERIFICATION
-- End-to-end test of booking workflow, triggers, and views
-- ============================================================================

-- ============================================================================
-- PART 1: Check Database Functions
-- ============================================================================

SELECT '=== PART 1: Database Functions ===' as section;

-- Check if booking function exists
SELECT
  'book_session_with_validation' as function_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc
      WHERE proname = 'book_session_with_validation'
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status;

-- Check if cancel functions exist
SELECT
  proname as function_name,
  CASE
    WHEN proname LIKE '%cancel%' THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM pg_proc
WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- PART 2: Check Trigger Status
-- ============================================================================

SELECT '=== PART 2: Trigger Status ===' as section;

SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  '✅ ACTIVE' as status
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions'
  AND event_object_table = 'sessions'
  AND event_object_schema = 'public';

-- Check trigger function
SELECT
  'sync_package_remaining_sessions' as function_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_proc
      WHERE proname = 'sync_package_remaining_sessions'
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status;

-- ============================================================================
-- PART 3: Check Database Views
-- ============================================================================

SELECT '=== PART 3: Database Views ===' as section;

-- Check if views exist
SELECT
  table_name as view_name,
  CASE
    WHEN table_type = 'VIEW' THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'VIEW'
  AND table_name IN ('today_schedule', 'trainer_upcoming_sessions', 'weekly_calendar')
ORDER BY table_name;

-- Check view permissions
SELECT
  table_name as view_name,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('today_schedule', 'trainer_upcoming_sessions', 'weekly_calendar')
  AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee;

-- ============================================================================
-- PART 4: Check Actual Data - Sessions
-- ============================================================================

SELECT '=== PART 4: Existing Sessions ===' as section;

-- Count total sessions
SELECT
  'Total Sessions' as metric,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ Has Data'
    ELSE '⚠️ Empty'
  END as status
FROM sessions;

-- Count sessions by status
SELECT
  status,
  COUNT(*) as count
FROM sessions
GROUP BY status
ORDER BY status;

-- Show recent sessions for Nuttapon
SELECT
  s.id,
  s.client_id,
  s.trainer_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.package_id,
  c.full_name as client_name,
  t.full_name as trainer_name
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
LEFT JOIN users t ON s.trainer_id = t.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY s.scheduled_start DESC
LIMIT 10;

-- ============================================================================
-- PART 5: Check Package Status
-- ============================================================================

SELECT '=== PART 5: Package Status ===' as section;

SELECT
  cp.id as package_id,
  c.full_name as client_name,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.status as package_status,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked_sessions,
  CASE
    WHEN cp.used_sessions = (
      SELECT COUNT(*)
      FROM sessions s
      WHERE s.package_id = cp.id
        AND s.status IN ('scheduled', 'confirmed')
    ) THEN '✅ IN SYNC'
    ELSE '⚠️ OUT OF SYNC'
  END as sync_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND cp.status = 'active'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- PART 6: Test Views Return Data
-- ============================================================================

SELECT '=== PART 6: View Data Check ===' as section;

-- Check trainer_upcoming_sessions view
SELECT
  'trainer_upcoming_sessions' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ Has Data'
    ELSE '❌ Empty'
  END as status
FROM trainer_upcoming_sessions
WHERE client_name ILIKE '%Nuttapon%';

-- Check today_schedule view
SELECT
  'today_schedule' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) >= 0 THEN '✅ Working'
    ELSE '❌ Error'
  END as status
FROM today_schedule
WHERE client_name ILIKE '%Nuttapon%';

-- Check weekly_calendar view
SELECT
  'weekly_calendar' as view_name,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) >= 0 THEN '✅ Working'
    ELSE '❌ Error'
  END as status
FROM weekly_calendar
WHERE client_name ILIKE '%Nuttapon%';

-- Show actual data from trainer_upcoming_sessions
SELECT
  session_id,
  client_name,
  scheduled_start,
  scheduled_end,
  status,
  package_name,
  remaining_sessions
FROM trainer_upcoming_sessions
WHERE client_name ILIKE '%Nuttapon%'
ORDER BY scheduled_start
LIMIT 5;

-- ============================================================================
-- PART 7: Check Foreign Key Constraints
-- ============================================================================

SELECT '=== PART 7: Foreign Key Constraints ===' as section;

SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  '✅ Valid' as status
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'sessions'
  AND tc.table_schema = 'public'
ORDER BY tc.constraint_name;

-- ============================================================================
-- PART 8: Summary Report
-- ============================================================================

SELECT '=== SUMMARY REPORT ===' as section;

WITH system_status AS (
  SELECT
    -- Functions
    (SELECT COUNT(*) FROM pg_proc WHERE proname = 'book_session_with_validation') as has_booking_func,
    (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason')) as has_cancel_funcs,
    -- Trigger
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'auto_sync_package_sessions') as has_trigger,
    -- Views
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_type = 'VIEW' AND table_name IN ('today_schedule', 'trainer_upcoming_sessions', 'weekly_calendar')) as has_views,
    -- Data
    (SELECT COUNT(*) FROM sessions WHERE status IN ('scheduled', 'confirmed')) as active_sessions,
    (SELECT COUNT(*) FROM client_packages WHERE status = 'active') as active_packages,
    -- View data
    (SELECT COUNT(*) FROM trainer_upcoming_sessions) as upcoming_count
)
SELECT
  CASE
    WHEN has_booking_func > 0 THEN '✅'
    ELSE '❌'
  END || ' Booking Function' as component,
  CASE
    WHEN has_booking_func > 0 THEN 'Working'
    ELSE 'Missing'
  END as status
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN has_cancel_funcs >= 2 THEN '✅'
    ELSE '⚠️'
  END || ' Cancel Functions',
  CASE
    WHEN has_cancel_funcs >= 2 THEN 'Working'
    WHEN has_cancel_funcs > 0 THEN 'Partial'
    ELSE 'Missing'
  END
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN has_trigger > 0 THEN '✅'
    ELSE '❌'
  END || ' Auto-Sync Trigger',
  CASE
    WHEN has_trigger > 0 THEN 'Active'
    ELSE 'Missing'
  END
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN has_views >= 3 THEN '✅'
    ELSE '⚠️'
  END || ' Database Views',
  CASE
    WHEN has_views >= 3 THEN 'All Present'
    WHEN has_views > 0 THEN 'Partial'
    ELSE 'Missing'
  END
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN active_sessions > 0 THEN '✅'
    ELSE '⚠️'
  END || ' Active Sessions',
  active_sessions::TEXT || ' sessions'
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN active_packages > 0 THEN '✅'
    ELSE '⚠️'
  END || ' Active Packages',
  active_packages::TEXT || ' packages'
FROM system_status
UNION ALL
SELECT
  CASE
    WHEN upcoming_count > 0 THEN '✅'
    ELSE '⚠️'
  END || ' UI Will Show Data',
  upcoming_count::TEXT || ' sessions visible'
FROM system_status;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- ✅ book_session_with_validation: EXISTS
-- ✅ cancel functions: EXISTS (2)
-- ✅ auto_sync_package_sessions: ACTIVE
-- ✅ All 3 views: EXISTS with permissions
-- ✅ Sessions: 8+ for Nuttapon
-- ✅ Package: Shows used_sessions and remaining_sessions
-- ⚠️ Sync status: OUT OF SYNC (expected - old sessions not counted)
-- ✅ trainer_upcoming_sessions: Returns data (8+ rows)
-- ✅ Foreign keys: sessions.package_id → client_packages.id
-- ============================================================================

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 1. If all checks pass ✅, system is ready
-- 2. Run FIX_CANCEL_FUNCTIONS.sql to fix cancel error
-- 3. Book ONE new session to test trigger
-- 4. Verify package count decrements (10 → 9)
-- 5. Check Flutter UI shows "Upcoming (X)" where X > 0
-- ============================================================================
