-- ============================================================================
-- CHECK: RLS policies on client_packages table
-- ============================================================================
-- The cancel function updates client_packages table too!
-- This might be where the ANY/ALL error is coming from now

SELECT '=== Checking client_packages RLS policies ===' as step;

SELECT
  tablename,
  policyname,
  cmd,
  qual as using_expression,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    WHEN with_check LIKE '%ANY%' OR with_check LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'client_packages'
ORDER BY policyname;

-- Also check if RLS is enabled
SELECT
  tablename,
  rowsecurity as rls_enabled,
  CASE
    WHEN rowsecurity = true THEN '⚠️ RLS Enabled'
    ELSE '✅ RLS Disabled'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'client_packages';

-- ============================================================================
-- If this shows ANY/ALL errors, we need to disable RLS here too!
-- ============================================================================
