-- ============================================================================
-- FORCE REMOVE ALL POLICIES - AGGRESSIVE VERSION
-- ============================================================================
-- This aggressively removes ALL policies no matter what
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Get list of all policies on users table and drop them
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
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Disable RLS
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Verify ALL policies are gone
SELECT
  COUNT(*) as remaining_policies,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ ALL POLICIES REMOVED'
    ELSE '❌ SOME POLICIES STILL EXIST'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users';

-- Verify RLS is disabled
SELECT
  tablename,
  CASE
    WHEN rowsecurity = false THEN '✅ RLS DISABLED'
    ELSE '❌ RLS STILL ENABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'users';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- remaining_policies: 0
-- status: ✅ ALL POLICIES REMOVED
-- RLS: ✅ RLS DISABLED
--
-- NOW YOU CAN TRY LOGGING IN OR REGISTERING!
-- ============================================================================
