-- ============================================================================
-- FIX: Infinite Recursion in RLS Policies
-- ============================================================================
-- Error: "infinite recursion detected in policy for relation 'users'"
-- This happens when RLS policies reference the same table they're protecting
--
-- Solution: Drop all problematic policies and recreate with proper checks
--
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

-- Step 3: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 4: Create SIMPLE, NON-RECURSIVE policies

-- Policy 1: Allow service role (Supabase backend) full access
-- This is safe and doesn't cause recursion
CREATE POLICY "service_role_full_access"
  ON public.users
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy 2: Allow authenticated users to INSERT their own profile
-- Uses auth.uid() which doesn't query users table
CREATE POLICY "users_insert_own_profile"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Policy 3: Allow authenticated users to SELECT their own profile
-- Uses auth.uid() which doesn't query users table
CREATE POLICY "users_select_own_profile"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 4: Allow authenticated users to UPDATE their own profile
-- Uses auth.uid() which doesn't query users table
CREATE POLICY "users_update_own_profile"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy 5: Allow authenticated users to SELECT users where they are the trainer
-- This one is more complex but avoids recursion by using trainer_clients table
CREATE POLICY "trainers_select_their_clients"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.trainer_clients tc
      WHERE tc.client_id = users.id
        AND tc.trainer_id = auth.uid()
    )
  );

-- Step 5: Verify policies are created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users'
ORDER BY policyname;

-- Expected: Should show 5 policies without recursion issues

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- ✅ Infinite recursion fixed
-- ✅ RLS is enabled with safe policies
-- ✅ Users can register without errors
--
-- NOW RUN THE USER SETUP:
-- After this script succeeds, run: COMPLETE_USER_SETUP.sql
-- Then you can register or log in!
-- ============================================================================

-- Optional: Also fix other tables that might have similar issues

-- Fix sessions table policies
ALTER TABLE public.sessions DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own sessions" ON public.sessions;
DROP POLICY IF EXISTS "Trainers can create sessions" ON public.sessions;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sessions_select_own"
  ON public.sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = client_id OR auth.uid() = trainer_id);

CREATE POLICY "sessions_insert_as_trainer"
  ON public.sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = trainer_id);

-- Fix client_packages table policies
ALTER TABLE public.client_packages DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own packages" ON public.client_packages;
ALTER TABLE public.client_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "packages_select_own"
  ON public.client_packages
  FOR SELECT
  TO authenticated
  USING (auth.uid() = client_id OR auth.uid() = trainer_id);

-- Fix trainer_clients table policies
ALTER TABLE public.trainer_clients DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Trainers can view own clients" ON public.trainer_clients;
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "trainer_clients_select_own"
  ON public.trainer_clients
  FOR SELECT
  TO authenticated
  USING (auth.uid() = trainer_id);

CREATE POLICY "trainer_clients_insert_own"
  ON public.trainer_clients
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = trainer_id);

-- ============================================================================
-- FINAL VERIFICATION
-- ============================================================================
SELECT
  'RLS Status' as check_type,
  tablename,
  CASE
    WHEN rowsecurity = true THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'sessions', 'client_packages', 'trainer_clients')
ORDER BY tablename;

-- All should show ✅ ENABLED

-- Count policies per table
SELECT
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'sessions', 'client_packages', 'trainer_clients')
GROUP BY tablename
ORDER BY tablename;

-- Should show:
-- users: 5 policies
-- sessions: 2 policies
-- client_packages: 1 policy
-- trainer_clients: 2 policies

-- ============================================================================
-- NOW YOU'RE READY TO REGISTER!
-- ============================================================================
