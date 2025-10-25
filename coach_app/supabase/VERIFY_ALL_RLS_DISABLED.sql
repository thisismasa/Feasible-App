-- ============================================================================
-- VERIFY: Show RLS status on ALL tables
-- ============================================================================

SELECT '=== ALL TABLES RLS STATUS ===' as step;

SELECT
  tablename,
  rowsecurity as rls_enabled,
  CASE
    WHEN rowsecurity = true THEN '❌ RLS ENABLED'
    ELSE '✅ RLS DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY
  rowsecurity DESC,  -- Show any enabled first
  tablename;

-- ============================================================================
-- Count tables with RLS enabled
-- ============================================================================

SELECT '=== SUMMARY ===' as step;

SELECT
  COUNT(*) FILTER (WHERE rowsecurity = true) as tables_with_rls_enabled,
  COUNT(*) FILTER (WHERE rowsecurity = false) as tables_with_rls_disabled,
  COUNT(*) as total_tables
FROM pg_tables
WHERE schemaname = 'public';

-- ============================================================================
-- Check if ANY policies still exist
-- ============================================================================

SELECT '=== REMAINING POLICIES ===' as step;

SELECT
  COUNT(*) as total_policies_remaining
FROM pg_policies
WHERE schemaname = 'public';

-- Should be 0!

SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ PERFECT - No RLS policies exist anywhere'
    ELSE '⚠️ WARNING - ' || COUNT(*) || ' policies still exist'
  END as policy_check
FROM pg_policies
WHERE schemaname = 'public';

-- ============================================================================
-- Final check
-- ============================================================================

SELECT
  CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_tables
      WHERE schemaname = 'public' AND rowsecurity = true
    )
    AND NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
    )
    THEN '✅✅✅ PERFECT - RLS completely disabled, no policies exist!'
    ELSE '❌ Some issues remain'
  END as final_status;
