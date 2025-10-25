-- ============================================================================
-- FIND: Which table is STILL causing the ANY/ALL error?
-- ============================================================================

SELECT '=== PART 1: All tables with RLS ENABLED ===' as step;

SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = true
ORDER BY tablename;

-- ============================================================================
-- PART 2: All tables with RLS policies (even if RLS is disabled)
-- ============================================================================

SELECT '=== PART 2: All tables that have RLS policies ===' as step;

SELECT DISTINCT
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- PART 3: ALL RLS policies with ANY/ALL syntax
-- ============================================================================

SELECT '=== PART 3: ALL policies with ANY/ALL (these cause the error) ===' as step;

SELECT
  tablename,
  policyname,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND (
    qual LIKE '%ANY%'
    OR qual LIKE '%ALL%'
    OR with_check LIKE '%ANY%'
    OR with_check LIKE '%ALL%'
  )
ORDER BY tablename, policyname;

-- ============================================================================
-- PART 4: Check trainer_clients table specifically
-- ============================================================================

SELECT '=== PART 4: trainer_clients table RLS status ===' as step;

-- Check if RLS is enabled
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'trainer_clients';

-- Check policies on trainer_clients
SELECT
  '  Policy: ' || policyname as policy_info,
  '  Command: ' || cmd as command_type,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'trainer_clients';

-- ============================================================================
-- This will show us exactly which table/policy is causing the error!
-- ============================================================================
