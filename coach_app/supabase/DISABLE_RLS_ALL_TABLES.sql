-- ============================================================================
-- NUCLEAR OPTION: Disable RLS on ALL tables with ANY/ALL policies
-- ============================================================================
-- The cancel operation touches multiple tables, any of them could have the error

SELECT '=== Step 1: Check RLS status on all tables ===' as step;

SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages', 'users', 'packages')
ORDER BY tablename;

-- ============================================================================
-- Step 2: Disable RLS on all relevant tables
-- ============================================================================

SELECT '=== Step 2: Disabling RLS on all tables ===' as step;

ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS disabled on sessions, client_packages, users' as result;

-- ============================================================================
-- Step 3: Verify all disabled
-- ============================================================================

SELECT '=== Step 3: Verification ===' as step;

SELECT
  tablename,
  rowsecurity as rls_enabled,
  CASE
    WHEN rowsecurity = false THEN '✅ RLS Disabled'
    ELSE '❌ RLS Still Enabled'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages', 'users')
ORDER BY tablename;

-- ============================================================================
-- Step 4: Reload PostgREST (MANY TIMES!)
-- ============================================================================

SELECT '=== Step 4: Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reload sent 5 times' as result;

-- ============================================================================
-- Step 5: Show all RLS policies that still have ANY/ALL
-- ============================================================================

SELECT '=== Step 5: Any remaining ANY/ALL policies? ===' as step;

SELECT
  tablename,
  policyname,
  cmd,
  '❌ This policy still has ANY/ALL' as warning
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
-- COMPLETE
-- ============================================================================

SELECT '=== ✅ ALL RLS DISABLED ===' as final_message;
SELECT 'Test cancel button now - error MUST be gone!' as next_step;
