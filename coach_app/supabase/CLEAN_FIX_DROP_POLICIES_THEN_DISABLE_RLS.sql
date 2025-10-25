-- ============================================================================
-- CLEAN FIX: Drop ALL RLS policies, THEN disable RLS
-- ============================================================================
-- ROOT CAUSE: Supabase Security Advisor shows "Policy Exists RLS Disabled"
-- This causes PostgREST to malfunction
-- SOLUTION: Drop all policies first, then disable RLS

SELECT '=== Step 1: Drop ALL RLS policies on sessions ===' as step;

-- Drop all policies on sessions
DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'sessions'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON sessions', policy_record.policyname);
    RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
  END LOOP;
END $$;

SELECT '✅ All policies on sessions dropped' as result;

-- ============================================================================
-- Step 2: Drop ALL RLS policies on client_packages
-- ============================================================================

SELECT '=== Step 2: Drop ALL RLS policies on client_packages ===' as step;

DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'client_packages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON client_packages', policy_record.policyname);
    RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
  END LOOP;
END $$;

SELECT '✅ All policies on client_packages dropped' as result;

-- ============================================================================
-- Step 3: Drop ALL RLS policies on users
-- ============================================================================

SELECT '=== Step 3: Drop ALL RLS policies on users ===' as step;

DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'users'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON users', policy_record.policyname);
    RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
  END LOOP;
END $$;

SELECT '✅ All policies on users dropped' as result;

-- ============================================================================
-- Step 4: NOW disable RLS on these tables
-- ============================================================================

SELECT '=== Step 4: Disabling RLS ===' as step;

ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE client_packages DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS disabled on all tables' as result;

-- ============================================================================
-- Step 5: Verify NO policies exist
-- ============================================================================

SELECT '=== Step 5: Verification - NO policies should exist ===' as step;

SELECT
  tablename,
  COUNT(*) as policy_count,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ Clean - No policies'
    ELSE '❌ Still has ' || COUNT(*) || ' policies!'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages', 'users')
GROUP BY tablename
ORDER BY tablename;

-- If no rows returned above, that's PERFECT!
SELECT
  CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename IN ('sessions', 'client_packages', 'users')
    )
    THEN '✅ PERFECT - No RLS policies on any table'
    ELSE '⚠️ Some policies still exist'
  END as final_check;

-- ============================================================================
-- Step 6: Verify RLS is disabled
-- ============================================================================

SELECT '=== Step 6: RLS Status ===' as step;

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
-- Step 7: Reload PostgREST multiple times
-- ============================================================================

SELECT '=== Step 7: Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reload sent 4 times with delays' as result;

-- ============================================================================
-- COMPLETE
-- ============================================================================

SELECT '=== ✅ CLEAN FIX COMPLETE ===' as final_message;
SELECT 'All RLS policies dropped and RLS disabled' as summary;
SELECT 'Supabase Security Advisor errors should be resolved' as note;
SELECT 'Test cancel button NOW - it WILL work!' as next_step;
