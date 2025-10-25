-- ============================================================================
-- COMPREHENSIVE ERROR INVESTIGATION
-- Check every possible error source in the booking system
-- ============================================================================

-- ============================================================================
-- ERROR CHECK 1: Foreign Key Violations
-- ============================================================================

SELECT '=== ERROR CHECK 1: Foreign Key Integrity ===' as check_section;

-- Check for sessions with invalid package_id
SELECT
  'Sessions with broken package FK' as error_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '❌ FOUND ERRORS'
    ELSE '✅ No errors'
  END as status
FROM sessions s
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.package_id IS NOT NULL
  AND cp.id IS NULL;

-- List the broken sessions if any
SELECT
  s.id as session_id,
  s.client_id,
  s.package_id as broken_package_id,
  s.scheduled_start,
  '❌ Package not found' as error
FROM sessions s
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.package_id IS NOT NULL
  AND cp.id IS NULL
LIMIT 10;

-- Check for sessions with invalid client_id
SELECT
  'Sessions with broken client FK' as error_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '❌ FOUND ERRORS'
    ELSE '✅ No errors'
  END as status
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
WHERE c.id IS NULL;

-- Check for sessions with invalid trainer_id
SELECT
  'Sessions with broken trainer FK' as error_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '❌ FOUND ERRORS'
    ELSE '✅ No errors'
  END as status
FROM sessions s
LEFT JOIN users t ON s.trainer_id = t.id
WHERE t.id IS NULL;

-- ============================================================================
-- ERROR CHECK 2: NULL Constraint Violations
-- ============================================================================

SELECT '=== ERROR CHECK 2: NULL Constraint Check ===' as check_section;

-- Check for required fields that are NULL
SELECT
  'Sessions with NULL scheduled_start' as error_type,
  COUNT(*) as count,
  CASE WHEN COUNT(*) > 0 THEN '❌ ERROR' ELSE '✅ OK' END as status
FROM sessions WHERE scheduled_start IS NULL
UNION ALL
SELECT
  'Sessions with NULL scheduled_end',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '❌ ERROR' ELSE '✅ OK' END
FROM sessions WHERE scheduled_end IS NULL
UNION ALL
SELECT
  'Sessions with NULL status',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '❌ ERROR' ELSE '✅ OK' END
FROM sessions WHERE status IS NULL
UNION ALL
SELECT
  'Sessions with NULL client_id',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '❌ ERROR' ELSE '✅ OK' END
FROM sessions WHERE client_id IS NULL
UNION ALL
SELECT
  'Sessions with NULL trainer_id',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '❌ ERROR' ELSE '✅ OK' END
FROM sessions WHERE trainer_id IS NULL;

-- ============================================================================
-- ERROR CHECK 3: Data Type Mismatches
-- ============================================================================

SELECT '=== ERROR CHECK 3: Data Type Issues ===' as check_section;

-- Check if scheduled_end is before scheduled_start (invalid)
SELECT
  'Sessions with end < start' as error_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '❌ LOGIC ERROR'
    ELSE '✅ No errors'
  END as status
FROM sessions
WHERE scheduled_end < scheduled_start;

-- List invalid sessions
SELECT
  id,
  scheduled_start,
  scheduled_end,
  scheduled_end - scheduled_start as duration,
  '❌ End time before start time' as error
FROM sessions
WHERE scheduled_end < scheduled_start
LIMIT 5;

-- ============================================================================
-- ERROR CHECK 4: View Definition Errors
-- ============================================================================

SELECT '=== ERROR CHECK 4: View Integrity ===' as check_section;

-- Try to query each view and catch errors
DO $$
DECLARE
  v_count INTEGER;
  v_error TEXT;
BEGIN
  -- Test today_schedule
  BEGIN
    SELECT COUNT(*) INTO v_count FROM today_schedule;
    RAISE NOTICE '✅ today_schedule: % rows', v_count;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ today_schedule ERROR: %', SQLERRM;
  END;

  -- Test trainer_upcoming_sessions
  BEGIN
    SELECT COUNT(*) INTO v_count FROM trainer_upcoming_sessions;
    RAISE NOTICE '✅ trainer_upcoming_sessions: % rows', v_count;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ trainer_upcoming_sessions ERROR: %', SQLERRM;
  END;

  -- Test weekly_calendar
  BEGIN
    SELECT COUNT(*) INTO v_count FROM weekly_calendar;
    RAISE NOTICE '✅ weekly_calendar: % rows', v_count;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ weekly_calendar ERROR: %', SQLERRM;
  END;
END $$;

-- ============================================================================
-- ERROR CHECK 5: Function Execution Errors
-- ============================================================================

SELECT '=== ERROR CHECK 5: Function Testing ===' as check_section;

-- Test book_session_with_validation function exists and is callable
SELECT
  'book_session_with_validation' as function_name,
  pg_get_function_arguments(oid) as parameters,
  prokind as function_type,
  prorettype::regtype as return_type,
  CASE
    WHEN prorettype::regtype::text = 'json' THEN '✅ Correct return type'
    ELSE '⚠️ Unexpected return type'
  END as status
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Test cancel functions
SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prorettype::regtype as return_type,
  CASE
    WHEN prorettype::regtype::text = 'json' THEN '✅ Correct return type'
    ELSE '⚠️ Check return type'
  END as status
FROM pg_proc
WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- ERROR CHECK 6: Trigger Execution Issues
-- ============================================================================

SELECT '=== ERROR CHECK 6: Trigger Status ===' as check_section;

-- Check trigger is enabled
SELECT
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation,
  action_statement,
  CASE
    WHEN action_statement LIKE '%sync_package_remaining_sessions%' THEN '✅ Correct function'
    ELSE '⚠️ Wrong function'
  END as validation
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions'
  AND event_object_schema = 'public';

-- Verify trigger function can execute
DO $$
BEGIN
  -- Check if function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'sync_package_remaining_sessions'
  ) THEN
    RAISE NOTICE '✅ Trigger function sync_package_remaining_sessions exists';
  ELSE
    RAISE NOTICE '❌ Trigger function sync_package_remaining_sessions NOT FOUND';
  END IF;
END $$;

-- ============================================================================
-- ERROR CHECK 7: Permission Issues
-- ============================================================================

SELECT '=== ERROR CHECK 7: Permissions ===' as check_section;

-- Check function permissions
SELECT
  routine_name as function_name,
  grantee,
  privilege_type,
  is_grantable,
  CASE
    WHEN grantee IN ('authenticated', 'public') AND privilege_type = 'EXECUTE'
    THEN '✅ Accessible'
    ELSE '⚠️ Check access'
  END as status
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND routine_name IN (
    'book_session_with_validation',
    'cancel_session_with_refund',
    'cancel_session_with_reason'
  )
ORDER BY routine_name, grantee;

-- Check view permissions
SELECT
  table_name as view_name,
  grantee,
  privilege_type,
  CASE
    WHEN grantee IN ('authenticated', 'anon') AND privilege_type = 'SELECT'
    THEN '✅ Accessible'
    ELSE '⚠️ Check access'
  END as status
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('today_schedule', 'trainer_upcoming_sessions', 'weekly_calendar')
ORDER BY table_name, grantee;

-- ============================================================================
-- ERROR CHECK 8: Package Count Sync Errors
-- ============================================================================

SELECT '=== ERROR CHECK 8: Package Sync Validation ===' as check_section;

SELECT
  cp.id,
  c.full_name as client_name,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  -- Calculate what it SHOULD be
  (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as actual_used,
  cp.total_sessions - (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as should_be_remaining,
  -- Validation
  CASE
    WHEN cp.used_sessions < 0 THEN '❌ Negative used_sessions!'
    WHEN cp.remaining_sessions < 0 THEN '❌ Negative remaining_sessions!'
    WHEN cp.used_sessions > cp.total_sessions THEN '❌ Used > Total!'
    WHEN cp.used_sessions != (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed'))
      THEN '⚠️ OUT OF SYNC (expected)'
    ELSE '✅ Valid'
  END as validation
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE cp.status = 'active'
ORDER BY validation DESC, cp.created_at DESC;

-- ============================================================================
-- ERROR CHECK 9: Duplicate or Conflicting Data
-- ============================================================================

SELECT '=== ERROR CHECK 9: Data Conflicts ===' as check_section;

-- Check for duplicate sessions (same client, trainer, time)
SELECT
  client_id,
  trainer_id,
  scheduled_start,
  COUNT(*) as duplicate_count,
  '⚠️ Duplicate sessions' as warning
FROM sessions
WHERE status IN ('scheduled', 'confirmed')
GROUP BY client_id, trainer_id, scheduled_start
HAVING COUNT(*) > 1;

-- Check for overlapping sessions for same trainer
WITH overlapping AS (
  SELECT
    s1.id as session1_id,
    s2.id as session2_id,
    s1.trainer_id,
    s1.scheduled_start as start1,
    s1.scheduled_end as end1,
    s2.scheduled_start as start2,
    s2.scheduled_end as end2
  FROM sessions s1
  JOIN sessions s2 ON s1.trainer_id = s2.trainer_id
    AND s1.id != s2.id
    AND s1.status IN ('scheduled', 'confirmed')
    AND s2.status IN ('scheduled', 'confirmed')
  WHERE (s1.scheduled_start, s1.scheduled_end) OVERLAPS (s2.scheduled_start, s2.scheduled_end)
)
SELECT
  'Overlapping trainer sessions' as conflict_type,
  COUNT(*) as count,
  CASE
    WHEN COUNT(*) > 0 THEN '⚠️ FOUND CONFLICTS'
    ELSE '✅ No conflicts'
  END as status
FROM overlapping;

-- ============================================================================
-- ERROR CHECK 10: Missing or Incomplete Data
-- ============================================================================

SELECT '=== ERROR CHECK 10: Data Completeness ===' as check_section;

-- Check if users have required fields
SELECT
  'Users missing full_name' as issue,
  COUNT(*) as count,
  CASE WHEN COUNT(*) > 0 THEN '⚠️ Data incomplete' ELSE '✅ OK' END as status
FROM users
WHERE full_name IS NULL OR full_name = ''
UNION ALL
SELECT
  'Users missing email',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '⚠️ Data incomplete' ELSE '✅ OK' END
FROM users
WHERE email IS NULL OR email = ''
UNION ALL
SELECT
  'Active packages missing package_name',
  COUNT(*),
  CASE WHEN COUNT(*) > 0 THEN '⚠️ Data incomplete' ELSE '✅ OK' END
FROM client_packages
WHERE status = 'active'
  AND (package_name IS NULL OR package_name = '');

-- ============================================================================
-- FINAL ERROR SUMMARY
-- ============================================================================

SELECT '=== FINAL ERROR SUMMARY ===' as check_section;

WITH error_counts AS (
  SELECT
    (SELECT COUNT(*) FROM sessions s LEFT JOIN client_packages cp ON s.package_id = cp.id WHERE s.package_id IS NOT NULL AND cp.id IS NULL) as broken_fks,
    (SELECT COUNT(*) FROM sessions WHERE scheduled_end < scheduled_start) as invalid_times,
    (SELECT COUNT(*) FROM sessions WHERE scheduled_start IS NULL OR scheduled_end IS NULL OR status IS NULL) as null_violations,
    (SELECT COUNT(*) FROM client_packages WHERE status = 'active' AND (used_sessions < 0 OR remaining_sessions < 0)) as negative_counts
)
SELECT
  'Broken Foreign Keys' as error_category,
  broken_fks as count,
  CASE WHEN broken_fks > 0 THEN '❌ FIX REQUIRED' ELSE '✅ OK' END as status
FROM error_counts
UNION ALL
SELECT
  'Invalid Time Ranges',
  invalid_times,
  CASE WHEN invalid_times > 0 THEN '❌ FIX REQUIRED' ELSE '✅ OK' END
FROM error_counts
UNION ALL
SELECT
  'NULL Constraint Violations',
  null_violations,
  CASE WHEN null_violations > 0 THEN '❌ FIX REQUIRED' ELSE '✅ OK' END
FROM error_counts
UNION ALL
SELECT
  'Negative Package Counts',
  negative_counts,
  CASE WHEN negative_counts > 0 THEN '❌ FIX REQUIRED' ELSE '✅ OK' END
FROM error_counts;

-- ============================================================================
-- INSTRUCTIONS:
-- ============================================================================
-- 1. Run this entire file in Supabase SQL Editor
-- 2. Check NOTICES tab for trigger function messages
-- 3. Look for any ❌ or ⚠️ symbols in results
-- 4. If errors found, note which section and what the error is
-- 5. Report back with specific error details
-- ============================================================================
