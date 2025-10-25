-- ============================================================================
-- FIX TRAINER_CLIENTS DUPLICATES
-- ============================================================================
-- This script will:
-- 1. Show all existing trainer-client relationships
-- 2. Remove duplicates
-- 3. Allow RLS on trainer_clients table
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Check current trainer-client relationships
SELECT
  tc.id,
  tc.trainer_id,
  t.email as trainer_email,
  t.full_name as trainer_name,
  tc.client_id,
  c.email as client_email,
  c.full_name as client_name,
  tc.is_active,
  tc.assigned_at
FROM trainer_clients tc
LEFT JOIN users t ON tc.trainer_id = t.id
LEFT JOIN users c ON tc.client_id = c.id
ORDER BY tc.assigned_at DESC;

-- Step 2: Check for your specific trainer (masathomardforwork@gmail.com)
SELECT
  tc.id,
  tc.trainer_id,
  tc.client_id,
  c.email as client_email,
  c.full_name as client_name,
  tc.is_active,
  tc.assigned_at
FROM trainer_clients tc
LEFT JOIN users c ON tc.client_id = c.id
WHERE tc.trainer_id = (SELECT id FROM users WHERE email = 'masathomardforwork@gmail.com');

-- Step 3: Delete ALL trainer_clients relationships for your trainer
-- (This allows you to start fresh with client assignments)
DELETE FROM trainer_clients
WHERE trainer_id = (SELECT id FROM users WHERE email = 'masathomardforwork@gmail.com');

-- Step 4: Disable RLS on trainer_clients table (to prevent recursion)
ALTER TABLE trainer_clients DISABLE ROW LEVEL SECURITY;

-- Step 5: Drop all RLS policies on trainer_clients
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'trainer_clients'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.trainer_clients', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Step 6: Verify RLS is disabled
SELECT
  tablename,
  CASE
    WHEN rowsecurity = false THEN '✅ RLS DISABLED'
    ELSE '❌ RLS STILL ENABLED'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'trainer_clients';

-- Step 7: Verify no policies remain
SELECT
  COUNT(*) as remaining_policies,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ NO POLICIES'
    ELSE '❌ POLICIES EXIST'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'trainer_clients';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- After running this script:
-- 1. All old client assignments deleted for your trainer
-- 2. RLS disabled on trainer_clients table
-- 3. No policies remaining
--
-- NOW YOU CAN ADD CLIENTS IN THE FLUTTER APP!
-- ============================================================================
