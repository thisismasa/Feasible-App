-- ============================================================================
-- FIX: Infinite Recursion in RLS Policies - USERS TABLE ONLY
-- ============================================================================
-- This script ONLY fixes the users table (doesn't touch other tables)
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Temporarily disable RLS on users table
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Trainers can view their clients" ON public.users;
DROP POLICY IF EXISTS "Trainers can view own clients" ON public.users;
DROP POLICY IF EXISTS "Users can view own sessions" ON public.users;
DROP POLICY IF EXISTS "Service role full access" ON public.users;
DROP POLICY IF EXISTS "Public read access" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON public.users;
DROP POLICY IF EXISTS "service_role_full_access" ON public.users;
DROP POLICY IF EXISTS "users_insert_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_select_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_update_own_profile" ON public.users;
DROP POLICY IF EXISTS "trainers_select_their_clients" ON public.users;

-- Step 3: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 4: Create SIMPLE, NON-RECURSIVE policies

-- Policy 1: Allow service role full access
CREATE POLICY "service_role_full_access"
  ON public.users
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy 2: Allow authenticated users to INSERT their own profile
CREATE POLICY "users_insert_own_profile"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Policy 3: Allow authenticated users to SELECT their own profile
CREATE POLICY "users_select_own_profile"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 4: Allow authenticated users to UPDATE their own profile
CREATE POLICY "users_update_own_profile"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Step 5: Verify policies are created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users'
ORDER BY policyname;

-- Expected: Should show 4 policies

-- Verify RLS is enabled
SELECT
  tablename,
  CASE
    WHEN rowsecurity = true THEN '✅ RLS ENABLED'
    ELSE '❌ RLS DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'users';

-- Expected: ✅ RLS ENABLED

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- ✅ Infinite recursion fixed for users table
-- ✅ RLS is enabled with safe policies
-- ✅ You can now register without recursion errors
--
-- NEXT STEP:
-- Run: COMPLETE_USER_SETUP.sql
-- Then try logging in or registering again!
-- ============================================================================
