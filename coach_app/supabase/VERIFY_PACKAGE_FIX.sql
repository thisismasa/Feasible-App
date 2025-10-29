-- ============================================================================
-- VERIFICATION: Check if FIX_PACKAGE_BOOKING_SYNC worked
-- ============================================================================

-- CHECK 1: Verify duplicate columns are gone
-- ============================================================================
SELECT
  '✅ CHECK 1: Column Structure' as test,
  CASE
    WHEN COUNT(*) FILTER (WHERE column_name = 'sessions_remaining') = 0
     AND COUNT(*) FILTER (WHERE column_name = 'sessions_used') = 0
     AND COUNT(*) FILTER (WHERE column_name = 'remaining_sessions') = 1
     AND COUNT(*) FILTER (WHERE column_name = 'used_sessions') = 1
    THEN '✅ PASS: Duplicate columns removed, correct columns exist'
    ELSE '❌ FAIL: Duplicate columns still exist'
  END as result
FROM information_schema.columns
WHERE table_name = 'client_packages'
  AND column_name IN ('sessions_remaining', 'sessions_used', 'remaining_sessions', 'used_sessions');

-- CHECK 2: Verify triggers exist
-- ============================================================================
SELECT
  '✅ CHECK 2: Triggers Created' as test,
  CASE
    WHEN COUNT(*) = 3 THEN '✅ PASS: All 3 triggers created'
    ELSE '❌ FAIL: Missing triggers (found ' || COUNT(*) || ' of 3)'
  END as result
FROM information_schema.triggers
WHERE trigger_name IN (
  'trigger_update_package_on_session_create',
  'trigger_update_package_on_session_complete',
  'trigger_restore_package_on_session_cancel'
);

-- CHECK 3: Verify function exists
-- ============================================================================
SELECT
  '✅ CHECK 3: Function Created' as test,
  CASE
    WHEN COUNT(*) = 1 THEN '✅ PASS: assign_package_to_client function exists'
    ELSE '❌ FAIL: Function not found'
  END as result
FROM information_schema.routines
WHERE routine_name = 'assign_package_to_client';

-- CHECK 4: Verify views are updated
-- ============================================================================
SELECT
  '✅ CHECK 4: Views Updated' as test,
  CASE
    WHEN COUNT(*) = 2 THEN '✅ PASS: Both views recreated'
    ELSE '❌ FAIL: Views missing (found ' || COUNT(*) || ' of 2)'
  END as result
FROM information_schema.views
WHERE table_name IN ('series_overview', 'waitlist_dashboard');

-- CHECK 5: Show current package status
-- ============================================================================
SELECT
  '📊 CURRENT PACKAGES' as info,
  cp.id,
  cp.package_name,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.used_sessions,
  cp.sessions_scheduled,
  cp.status,
  u.full_name as client_name
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.status = 'active'
ORDER BY cp.updated_at DESC
LIMIT 5;

-- CHECK 6: Show trigger details
-- ============================================================================
SELECT
  '📋 TRIGGER DETAILS' as info,
  trigger_name,
  event_manipulation as event,
  action_timing as timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%package%'
ORDER BY trigger_name;

-- SUMMARY
-- ============================================================================
SELECT '✅✅✅ VERIFICATION COMPLETE ✅✅✅' as summary;
