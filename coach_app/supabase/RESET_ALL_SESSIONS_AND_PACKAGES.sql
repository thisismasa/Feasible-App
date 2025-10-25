-- ============================================================================
-- RESET: Delete all sessions and reset all client packages to 0
-- ============================================================================
-- This will give you a clean slate to test from the beginning

SELECT '=== STEP 1: Show current state before reset ===' as step;

SELECT
  'Sessions count: ' || COUNT(*) as current_sessions
FROM sessions;

SELECT
  'Client packages count: ' || COUNT(*) as current_packages,
  'Total used sessions: ' || COALESCE(SUM(used_sessions), 0) as total_used,
  'Total remaining: ' || COALESCE(SUM(remaining_sessions), 0) as total_remaining
FROM client_packages;

-- ============================================================================
-- STEP 2: Delete ALL sessions (start fresh)
-- ============================================================================

SELECT '=== STEP 2: Deleting all sessions ===' as step;

DELETE FROM sessions;

SELECT 'All sessions deleted' as result;

-- ============================================================================
-- STEP 3: Reset all client packages to initial state
-- ============================================================================

SELECT '=== STEP 3: Resetting all client packages ===' as step;

UPDATE client_packages
SET
  used_sessions = 0,
  remaining_sessions = total_sessions,  -- Reset to full package amount
  updated_at = NOW();

SELECT
  'Packages reset: ' || COUNT(*) as packages_reset,
  'Total sessions available: ' || COALESCE(SUM(remaining_sessions), 0) as total_available
FROM client_packages;

-- ============================================================================
-- STEP 4: Verify clean state
-- ============================================================================

SELECT '=== STEP 4: Verify clean state ===' as step;

-- Check sessions
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ No sessions - Clean state'
    ELSE '❌ Still has ' || COUNT(*) || ' sessions'
  END as sessions_check
FROM sessions;

-- Check packages
SELECT
  id,
  client_id,
  total_sessions,
  used_sessions,
  remaining_sessions,
  CASE
    WHEN used_sessions = 0 AND remaining_sessions = total_sessions
    THEN '✅ Reset correctly'
    ELSE '⚠️ Not fully reset'
  END as status
FROM client_packages
ORDER BY created_at;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- - All sessions deleted (count = 0)
-- - All client_packages have used_sessions = 0
-- - All client_packages have remaining_sessions = total_sessions
-- ============================================================================

SELECT '=== ✅ RESET COMPLETE ===' as final_message;
SELECT 'Database is now in clean initial state. Ready to test from beginning!' as note;
