-- ============================================================================
-- CHECK: Verify the new policies exist and are clean
-- ============================================================================

SELECT
  policyname,
  cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    ELSE '✅ CLEAN'
  END as status,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('trainers_delete_sessions', 'trainers_update_sessions')
ORDER BY policyname;

-- ============================================================================
-- Also check if OLD policies still exist
-- ============================================================================

SELECT
  '❌ OLD POLICIES:' as warning,
  policyname,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('Trainers can delete own sessions', 'Trainers can update own sessions')
ORDER BY policyname;

-- ============================================================================
-- Show ALL policies on sessions table
-- ============================================================================

SELECT
  'ALL POLICIES:' as info,
  policyname,
  cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
ORDER BY policyname;
