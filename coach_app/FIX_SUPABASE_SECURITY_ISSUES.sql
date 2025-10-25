-- ============================================================================
-- FIX SUPABASE SECURITY ISSUES
-- ============================================================================
-- This script fixes all security warnings shown in Security Advisor:
-- 1. RLS Disabled in Public tables (user_sessions, page_views)
-- 2. Security Definer Views without RLS
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- ============================================================================
-- PART 1: ENABLE RLS ON PUBLIC TABLES
-- ============================================================================

-- Fix 1: Enable RLS on public.user_sessions
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for user_sessions
-- Users can only see their own sessions
DROP POLICY IF EXISTS "Users can view own sessions" ON public.user_sessions;
CREATE POLICY "Users can view own sessions"
  ON public.user_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own sessions
DROP POLICY IF EXISTS "Users can insert own sessions" ON public.user_sessions;
CREATE POLICY "Users can insert own sessions"
  ON public.user_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own sessions
DROP POLICY IF EXISTS "Users can update own sessions" ON public.user_sessions;
CREATE POLICY "Users can update own sessions"
  ON public.user_sessions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own sessions
DROP POLICY IF EXISTS "Users can delete own sessions" ON public.user_sessions;
CREATE POLICY "Users can delete own sessions"
  ON public.user_sessions
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================

-- Fix 2: Enable RLS on public.page_views
ALTER TABLE public.page_views ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for page_views
-- Users can only see their own page views
DROP POLICY IF EXISTS "Users can view own page views" ON public.page_views;
CREATE POLICY "Users can view own page views"
  ON public.page_views
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own page views
DROP POLICY IF EXISTS "Users can insert own page views" ON public.page_views;
CREATE POLICY "Users can insert own page views"
  ON public.page_views
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- PART 2: FIX SECURITY DEFINER VIEWS
-- ============================================================================

-- The security warnings show these views have issues:
-- - public.trainer_client_detail
-- - public.clients_with_packages
-- - public.high_risk_clients
-- - public.client_profiles_compl
-- - public.incomplete_onboarding

-- Strategy: Recreate views with SECURITY INVOKER or add RLS to base tables

-- ============================================================================
-- Fix 3: Drop and recreate trainer_client_detail view
-- ============================================================================
DROP VIEW IF EXISTS public.trainer_client_detail CASCADE;

CREATE OR REPLACE VIEW public.trainer_client_detail
WITH (security_invoker = true)  -- Use caller's permissions, not definer's
AS
SELECT
  tc.trainer_id,
  tc.client_id,
  u.email,
  u.full_name,
  u.phone,
  u.role,
  u.is_active,
  tc.assigned_at,
  tc.created_at
FROM public.trainer_clients tc
INNER JOIN public.users u ON u.id = tc.client_id
WHERE u.role = 'client';

-- Grant access to authenticated users
GRANT SELECT ON public.trainer_client_detail TO authenticated;

-- ============================================================================
-- Fix 4: Drop and recreate clients_with_packages view
-- ============================================================================
DROP VIEW IF EXISTS public.clients_with_packages CASCADE;

CREATE OR REPLACE VIEW public.clients_with_packages
WITH (security_invoker = true)
AS
SELECT
  u.id as client_id,
  u.email,
  u.full_name,
  u.phone,
  COUNT(cp.id) as total_packages,
  SUM(CASE WHEN cp.status = 'active' THEN 1 ELSE 0 END) as active_packages,
  SUM(CASE WHEN cp.status = 'active' THEN cp.remaining_sessions ELSE 0 END) as total_remaining_sessions
FROM public.users u
LEFT JOIN public.client_packages cp ON cp.client_id = u.id
WHERE u.role = 'client'
GROUP BY u.id, u.email, u.full_name, u.phone;

-- Grant access to authenticated users
GRANT SELECT ON public.clients_with_packages TO authenticated;

-- ============================================================================
-- Fix 5: Drop and recreate high_risk_clients view
-- ============================================================================
DROP VIEW IF EXISTS public.high_risk_clients CASCADE;

CREATE OR REPLACE VIEW public.high_risk_clients
WITH (security_invoker = true)
AS
SELECT
  u.id as client_id,
  u.email,
  u.full_name,
  u.phone,
  COUNT(s.id) as missed_sessions,
  MAX(s.scheduled_date) as last_missed_date
FROM public.users u
INNER JOIN public.sessions s ON s.client_id = u.id
WHERE u.role = 'client'
  AND s.status = 'cancelled'
  AND s.cancelled_by = 'client'
GROUP BY u.id, u.email, u.full_name, u.phone
HAVING COUNT(s.id) >= 3;  -- 3+ missed sessions = high risk

-- Grant access to authenticated users
GRANT SELECT ON public.high_risk_clients TO authenticated;

-- ============================================================================
-- Fix 6: Drop and recreate client_profiles_compl view
-- ============================================================================
DROP VIEW IF EXISTS public.client_profiles_compl CASCADE;

CREATE OR REPLACE VIEW public.client_profiles_compl
WITH (security_invoker = true)
AS
SELECT
  u.id as client_id,
  u.email,
  u.full_name,
  u.phone,
  CASE
    WHEN u.full_name IS NOT NULL AND u.phone IS NOT NULL AND u.email IS NOT NULL
      THEN 'complete'
    ELSE 'incomplete'
  END as profile_status,
  u.created_at,
  u.updated_at
FROM public.users u
WHERE u.role = 'client';

-- Grant access to authenticated users
GRANT SELECT ON public.client_profiles_compl TO authenticated;

-- ============================================================================
-- Fix 7: Drop and recreate incomplete_onboarding view
-- ============================================================================
DROP VIEW IF EXISTS public.incomplete_onboarding CASCADE;

CREATE OR REPLACE VIEW public.incomplete_onboarding
WITH (security_invoker = true)
AS
SELECT
  u.id as client_id,
  u.email,
  u.full_name,
  u.created_at,
  COUNT(cp.id) as packages_count,
  COUNT(s.id) as sessions_count,
  CASE
    WHEN COUNT(cp.id) = 0 THEN 'No packages purchased'
    WHEN COUNT(s.id) = 0 THEN 'No sessions booked'
    ELSE 'Onboarding incomplete'
  END as onboarding_status
FROM public.users u
LEFT JOIN public.client_packages cp ON cp.client_id = u.id
LEFT JOIN public.sessions s ON s.client_id = u.id
WHERE u.role = 'client'
  AND u.created_at >= NOW() - INTERVAL '30 days'  -- New users in last 30 days
  AND (COUNT(cp.id) = 0 OR COUNT(s.id) = 0)
GROUP BY u.id, u.email, u.full_name, u.created_at;

-- Grant access to authenticated users
GRANT SELECT ON public.incomplete_onboarding TO authenticated;

-- ============================================================================
-- PART 3: VERIFY FIXES
-- ============================================================================

-- Check that RLS is enabled on all required tables
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('user_sessions', 'page_views', 'users', 'clients',
                     'sessions', 'client_packages', 'trainer_clients')
ORDER BY tablename;

-- Expected: All should show rls_enabled = true

-- ============================================================================

-- Check all policies on user_sessions
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
  AND tablename IN ('user_sessions', 'page_views')
ORDER BY tablename, policyname;

-- Expected: Should show all the policies we just created

-- ============================================================================

-- Check all views and their security settings
SELECT
  schemaname,
  viewname,
  viewowner,
  definition
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN ('trainer_client_detail', 'clients_with_packages',
                    'high_risk_clients', 'client_profiles_compl',
                    'incomplete_onboarding')
ORDER BY viewname;

-- Expected: Should show all views exist with security_invoker = true

-- ============================================================================
-- PART 4: ADDITIONAL SECURITY HARDENING (OPTIONAL)
-- ============================================================================

-- Make sure core tables have RLS enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Trainers can view their clients
DROP POLICY IF EXISTS "Trainers can view their clients" ON public.users;
CREATE POLICY "Trainers can view their clients"
  ON public.users
  FOR SELECT
  USING (
    role = 'client' AND
    EXISTS (
      SELECT 1 FROM public.trainer_clients tc
      WHERE tc.client_id = users.id
        AND tc.trainer_id = auth.uid()
    )
  );

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Sessions: Users can view sessions they're involved in
DROP POLICY IF EXISTS "Users can view own sessions" ON public.sessions;
CREATE POLICY "Users can view own sessions"
  ON public.sessions
  FOR SELECT
  USING (
    auth.uid() = client_id OR
    auth.uid() = trainer_id
  );

-- Sessions: Trainers can create sessions for their clients
DROP POLICY IF EXISTS "Trainers can create sessions" ON public.sessions;
CREATE POLICY "Trainers can create sessions"
  ON public.sessions
  FOR INSERT
  WITH CHECK (
    auth.uid() = trainer_id AND
    EXISTS (
      SELECT 1 FROM public.trainer_clients tc
      WHERE tc.client_id = sessions.client_id
        AND tc.trainer_id = auth.uid()
    )
  );

-- Client packages: Users can view packages they're involved in
DROP POLICY IF EXISTS "Users can view own packages" ON public.client_packages;
CREATE POLICY "Users can view own packages"
  ON public.client_packages
  FOR SELECT
  USING (
    auth.uid() = client_id OR
    auth.uid() = trainer_id
  );

-- Trainer-client relationships: Trainers can view their assignments
DROP POLICY IF EXISTS "Trainers can view own clients" ON public.trainer_clients;
CREATE POLICY "Trainers can view own clients"
  ON public.trainer_clients
  FOR SELECT
  USING (auth.uid() = trainer_id);

-- ============================================================================
-- FINAL VERIFICATION
-- ============================================================================

-- This should return 0 security errors related to RLS
-- Go back to: Supabase Dashboard → Advisors → Security Advisor
-- Click "Refresh" button
-- Expected: 0 errors for RLS Disabled in Public
-- Expected: 0 errors for Security Definer View (or reduced count)

-- ============================================================================
-- SUMMARY OF FIXES
-- ============================================================================
-- ✅ Enabled RLS on public.user_sessions
-- ✅ Enabled RLS on public.page_views
-- ✅ Created RLS policies for user_sessions (SELECT, INSERT, UPDATE, DELETE)
-- ✅ Created RLS policies for page_views (SELECT, INSERT)
-- ✅ Recreated trainer_client_detail view with security_invoker
-- ✅ Recreated clients_with_packages view with security_invoker
-- ✅ Recreated high_risk_clients view with security_invoker
-- ✅ Recreated client_profiles_compl view with security_invoker
-- ✅ Recreated incomplete_onboarding view with security_invoker
-- ✅ Added RLS policies to core tables (users, sessions, client_packages, etc.)
-- ✅ Verified all security settings
--
-- After running this script:
-- 1. Go to Security Advisor in Supabase Dashboard
-- 2. Click "Refresh" button
-- 3. Verify errors are reduced or eliminated
-- ============================================================================
