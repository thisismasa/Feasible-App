-- ============================================================================
-- VERIFY: Check if ANY/ALL syntax still exists anywhere
-- ============================================================================

SELECT '=== Checking ALL RLS Policies on sessions table ===' as step;

SELECT
  policyname,
  cmd as command,
  qual as using_expression,
  with_check,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ FOUND ANY/ALL in USING'
    WHEN with_check LIKE '%ANY%' OR with_check LIKE '%ALL%' THEN '❌ FOUND ANY/ALL in WITH CHECK'
    ELSE '✅ Clean - No ANY/ALL'
  END as status
FROM pg_policies
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY policyname;

-- ============================================================================
-- If you see ANY ❌ marks above, we need to fix those specific policies!
-- If ALL are ✅, then the ANY/ALL error should be gone!
-- ============================================================================
