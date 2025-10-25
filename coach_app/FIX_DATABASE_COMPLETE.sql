-- ============================================================================
-- COMPLETE DATABASE FIX - RESTORE TO NORMAL STATE
-- ============================================================================
-- This script will:
-- 1. Fix authentication issues (confirm email, unban user)
-- 2. Ensure user exists in public.users table
-- 3. Verify packages have correct session counts
-- 4. Check client_packages table structure
-- 5. Verify payment_transactions table
-- 6. Verify all triggers are properly disabled
-- 7. Show final status of everything
-- ============================================================================

-- ============================================================================
-- PART 1: FIX AUTHENTICATION
-- ============================================================================

-- Step 1: Force confirm email
UPDATE auth.users
SET
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com';

-- Step 2: Unban user if banned
UPDATE auth.users
SET
  banned_until = NULL,
  updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND banned_until IS NOT NULL;

-- Step 3: Ensure user exists in public.users table
INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
SELECT
  id,
  email,
  COALESCE(raw_user_meta_data->>'full_name', 'Masatho Mard'),
  'trainer',
  true,
  created_at,
  NOW()
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = COALESCE(EXCLUDED.full_name, users.full_name),
  role = 'trainer',
  is_active = true,
  updated_at = NOW();

-- ============================================================================
-- PART 2: FIX PACKAGE DATA
-- ============================================================================

-- Step 4: Fix all "10-Session Package" entries to have 10 sessions
UPDATE packages
SET
  sessions = 10,
  updated_at = NOW()
WHERE name = '10-Session Package'
  AND (sessions = 0 OR sessions IS NULL);

-- Step 5: Fix any other packages that might have 0 sessions
UPDATE packages
SET
  sessions = CASE
    WHEN name LIKE '%5%' THEN 5
    WHEN name LIKE '%10%' THEN 10
    WHEN name LIKE '%20%' THEN 20
    WHEN name LIKE '%30%' THEN 30
    ELSE 10  -- default to 10 if unclear
  END,
  updated_at = NOW()
WHERE sessions = 0 OR sessions IS NULL;

-- ============================================================================
-- PART 3: VERIFY TRIGGERS ARE DISABLED
-- ============================================================================

-- Step 6: Check trigger status (for information only)
SELECT
  t.tgname as trigger_name,
  c.relname as table_name,
  CASE t.tgenabled
    WHEN 'O' THEN '⚠️ ENABLED (WILL CAUSE ISSUES!)'
    WHEN 'D' THEN '✅ DISABLED (CORRECT)'
  END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname IN ('users', 'bookings', 'client_packages', 'payment_transactions')
  AND t.tgisinternal = false
ORDER BY c.relname, t.tgname;

-- ============================================================================
-- PART 4: VERIFY CLIENT_PACKAGES TABLE STRUCTURE
-- ============================================================================

-- Step 7: Check if sessions_remaining column exists and is GENERATED
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable,
  CASE
    WHEN column_default LIKE '%GENERATED%' OR generation_expression IS NOT NULL THEN '✅ GENERATED COLUMN'
    ELSE 'Regular column'
  END as column_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
  AND column_name IN ('total_sessions', 'sessions_used', 'sessions_remaining')
ORDER BY ordinal_position;

-- ============================================================================
-- PART 5: COMPREHENSIVE VERIFICATION
-- ============================================================================

-- Step 8: Authentication Status
SELECT
  '🔐 AUTHENTICATION STATUS' as section,
  '' as check_type,
  '' as status;

SELECT
  'Email Confirmation' as check_type,
  CASE
    WHEN email_confirmed_at IS NOT NULL THEN '✅ CONFIRMED at ' || email_confirmed_at::text
    ELSE '❌ NOT CONFIRMED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'

UNION ALL

SELECT
  'User in public.users' as check_type,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM public.users
      WHERE email = 'masathomardforwork@gmail.com'
        AND role = 'trainer'
        AND is_active = true
    ) THEN '✅ EXISTS (role=trainer, active=true)'
    ELSE '❌ MISSING or INACTIVE'
  END as status

UNION ALL

SELECT
  'Not Banned' as check_type,
  CASE
    WHEN banned_until IS NULL THEN '✅ NOT BANNED'
    WHEN banned_until < NOW() THEN '✅ BAN EXPIRED'
    ELSE '❌ CURRENTLY BANNED until ' || banned_until::text
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 9: Package Status
SELECT
  '📦 PACKAGE STATUS' as section,
  '' as package_name,
  '' as sessions_count,
  '' as status;

SELECT
  name as package_name,
  sessions as sessions_count,
  CASE
    WHEN sessions > 0 THEN '✅ CORRECT'
    WHEN sessions = 0 THEN '❌ ZERO SESSIONS (WILL CAUSE ISSUES!)'
    WHEN sessions IS NULL THEN '❌ NULL SESSIONS'
  END as status
FROM packages
WHERE name LIKE '%Session%'
ORDER BY name;

-- Step 10: Trigger Status Summary
SELECT
  '⚙️ TRIGGER STATUS' as section,
  '' as trigger_info,
  '' as recommendation;

SELECT
  COUNT(*) || ' triggers on payment/package tables' as trigger_info,
  CASE
    WHEN COUNT(CASE WHEN t.tgenabled = 'O' THEN 1 END) > 0
    THEN '⚠️ DISABLE THEM - Run RUN_THIS_FIX_TRIGGERS.sql'
    ELSE '✅ ALL DISABLED - Good to go!'
  END as recommendation
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname IN ('users', 'bookings', 'client_packages', 'payment_transactions')
  AND t.tgisinternal = false;

-- Step 11: Database Health Summary
SELECT
  '🏥 DATABASE HEALTH SUMMARY' as section,
  '' as component,
  '' as status;

SELECT
  'User Account' as component,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM auth.users au
      JOIN public.users pu ON au.id = pu.id
      WHERE au.email = 'masathomardforwork@gmail.com'
        AND au.email_confirmed_at IS NOT NULL
        AND (au.banned_until IS NULL OR au.banned_until < NOW())
        AND pu.is_active = true
        AND pu.role = 'trainer'
    ) THEN '✅ HEALTHY'
    ELSE '❌ NEEDS ATTENTION'
  END as status

UNION ALL

SELECT
  'Package Data' as component,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM packages
      WHERE name LIKE '%Session%'
        AND (sessions = 0 OR sessions IS NULL)
    ) THEN '❌ HAS PACKAGES WITH 0 SESSIONS'
    ELSE '✅ ALL PACKAGES HAVE SESSION COUNTS'
  END as status

UNION ALL

SELECT
  'Triggers' as component,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      WHERE c.relname IN ('client_packages', 'payment_transactions')
        AND t.tgisinternal = false
        AND t.tgenabled = 'O'
    ) THEN '⚠️ SOME ENABLED (Will cause "3 rows" error)'
    ELSE '✅ ALL DISABLED'
  END as status;

-- ============================================================================
-- FINAL INSTRUCTIONS
-- ============================================================================

SELECT
  '📋 NEXT STEPS' as section,
  '' as step,
  '' as action;

SELECT
  'Step 1' as step,
  'Reset your password via Dashboard (Authentication → Users → Click on your user → Reset Password)' as action

UNION ALL

SELECT
  'Step 2' as step,
  'Test login in Flutter app with email: masathomardforwork@gmail.com' as action

UNION ALL

SELECT
  'Step 3' as step,
  'Verify packages show "10 sessions" (not "0 sessions") when adding payment' as action

UNION ALL

SELECT
  'Step 4' as step,
  'If you see "3 rows returned" error, run RUN_THIS_FIX_TRIGGERS.sql' as action;

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- After running this script, you should see:
--
-- 🔐 AUTHENTICATION STATUS
--   ✅ Email Confirmation: CONFIRMED
--   ✅ User in public.users: EXISTS (role=trainer, active=true)
--   ✅ Not Banned: NOT BANNED
--
-- 📦 PACKAGE STATUS
--   ✅ All packages have session counts > 0
--   ✅ "10-Session Package" has sessions = 10
--
-- ⚙️ TRIGGER STATUS
--   ✅ ALL DISABLED - Good to go!
--
-- 🏥 DATABASE HEALTH SUMMARY
--   ✅ User Account: HEALTHY
--   ✅ Package Data: ALL PACKAGES HAVE SESSION COUNTS
--   ✅ Triggers: ALL DISABLED
--
-- ============================================================================
-- IMPORTANT: This script CANNOT reset your password!
-- You MUST reset password manually via Supabase Dashboard:
-- 1. Go to Authentication → Users
-- 2. Click on: masathomardforwork@gmail.com
-- 3. Click "..." menu or "Update User"
-- 4. Set new password (recommended: Coach2025!)
-- 5. Save
-- ============================================================================
