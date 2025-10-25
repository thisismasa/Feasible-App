-- ============================================================================
-- COMPREHENSIVE VERIFICATION: All Fixes Applied Correctly
-- ============================================================================

SELECT '=== STEP 1: Verify all database functions exist ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prorettype::regtype as return_type,
  CASE
    WHEN proname = 'book_session_with_validation' THEN '✅ Booking with conflict detection'
    WHEN proname = 'cancel_session_with_reason' THEN '✅ Cancel with reason (refunds package)'
    WHEN proname = 'cancel_session_with_refund' THEN '✅ Cancel with refund option'
    ELSE '✅ Ready'
  END as purpose
FROM pg_proc
WHERE proname IN ('book_session_with_validation', 'cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- STEP 2: Verify booking function has conflict detection
-- ============================================================================

SELECT '=== STEP 2: Check booking function has conflict detection ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%You already have a session booked at this time%'
    THEN '✅ YES - Client conflict check present'
    ELSE '❌ NO - Missing client conflict check!'
  END as has_client_check,
  CASE
    WHEN prosrc LIKE '%Trainer is already booked at this time%'
    THEN '✅ YES - Trainer conflict check present'
    ELSE '❌ NO - Missing trainer conflict check!'
  END as has_trainer_check
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 3: Verify cancel functions use IN instead of ANY
-- ============================================================================

SELECT '=== STEP 3: Verify cancel functions fixed (IN vs ANY) ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%IN (''scheduled'', ''confirmed'')%'
    THEN '✅ FIXED - Uses IN clause'
    WHEN prosrc LIKE '%ANY(ARRAY%'
    THEN '❌ ERROR - Still uses ANY/ALL'
    ELSE '⚠️ UNKNOWN - Cannot detect syntax'
  END as syntax_status
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- STEP 4: Verify trigger exists and is active
-- ============================================================================

SELECT '=== STEP 4: Verify auto-sync trigger ===' as step;

SELECT
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as is_enabled,
  CASE
    WHEN tgenabled = 'O' THEN '✅ ENABLED'
    WHEN tgenabled = 'D' THEN '❌ DISABLED'
    ELSE '⚠️ UNKNOWN'
  END as status
FROM pg_trigger
WHERE tgname = 'auto_sync_package_sessions';

-- ============================================================================
-- STEP 5: Check current package state
-- ============================================================================

SELECT '=== STEP 5: Current package state for Nuttapon ===' as step;

SELECT
  cp.id as package_id,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  COUNT(s.id) as actual_booked_sessions,
  CASE
    WHEN cp.used_sessions = COUNT(s.id) THEN '✅ IN SYNC'
    ELSE '⚠️ OUT OF SYNC'
  END as sync_status
FROM client_packages cp
JOIN users u ON u.id = cp.client_id
LEFT JOIN sessions s ON s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')
WHERE u.full_name ILIKE '%Nuttapon%'
  AND cp.status = 'active'
GROUP BY cp.id, cp.total_sessions, cp.used_sessions, cp.remaining_sessions;

-- ============================================================================
-- STEP 6: Check for any duplicate sessions
-- ============================================================================

SELECT '=== STEP 6: Check for duplicate sessions ===' as step;

SELECT
  TO_CHAR(s.scheduled_start, 'YYYY-MM-DD HH24:MI') as session_time,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 1 THEN '❌ DUPLICATE!'
    ELSE '✅ OK'
  END as status
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.status IN ('scheduled', 'confirmed')
GROUP BY s.scheduled_start
HAVING COUNT(*) > 1
ORDER BY s.scheduled_start;

-- ============================================================================
-- STEP 7: Verify no ANY/ALL syntax in active functions
-- ============================================================================

SELECT '=== STEP 7: Final check - no ANY/ALL issues ===' as step;

SELECT
  COUNT(*) as functions_with_any_all_issues,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ ALL CLEAR - No ANY/ALL issues found'
    ELSE '❌ PROBLEM - Found ' || COUNT(*) || ' functions with ANY/ALL issues'
  END as status
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND prosrc LIKE '%ANY(ARRAY%'
  AND proname IN ('book_session_with_validation', 'cancel_session_with_reason', 'cancel_session_with_refund');

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- STEP 1: Shows all 3 functions with correct return types
-- STEP 2: Shows ✅ YES for both client and trainer conflict checks
-- STEP 3: Shows ✅ FIXED for both cancel functions
-- STEP 4: Shows ✅ ENABLED for trigger
-- STEP 5: Shows ✅ IN SYNC for package
-- STEP 6: Should return 0 rows (no duplicates)
-- STEP 7: Shows ✅ ALL CLEAR
-- ============================================================================
