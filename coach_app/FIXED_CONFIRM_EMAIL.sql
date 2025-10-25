-- ============================================================================
-- FIXED: CONFIRM EMAIL AND FIX LOGIN ISSUES
-- ============================================================================
-- This script fixes the "Invalid login credentials" error by:
-- 1. Confirming the email address
-- 2. Ensuring user exists in public.users table
-- 3. Verifying all settings are correct
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Force confirm email for your user
UPDATE auth.users
SET
  email_confirmed_at = NOW(),
  updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND email_confirmed_at IS NULL;

-- Verify email is now confirmed
SELECT
  id,
  email,
  email_confirmed_at,
  CASE
    WHEN email_confirmed_at IS NOT NULL THEN '✅ CONFIRMED'
    ELSE '❌ NOT CONFIRMED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 2: Ensure user exists in public.users table
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

-- Verify user exists in public.users
SELECT
  id,
  email,
  full_name,
  role,
  is_active,
  CASE
    WHEN role = 'trainer' AND is_active = true THEN '✅ READY'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 3: Check if user is banned or locked
SELECT
  id,
  email,
  banned_until,
  CASE
    WHEN banned_until IS NULL THEN '✅ NOT BANNED'
    WHEN banned_until < NOW() THEN '✅ BAN EXPIRED'
    ELSE '❌ CURRENTLY BANNED'
  END as ban_status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 4: If banned, unban the user
UPDATE auth.users
SET
  banned_until = NULL,
  updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND banned_until IS NOT NULL;

-- Step 5: Final verification - Should show all green checks
SELECT
  'Email Confirmation' as check_type,
  CASE
    WHEN email_confirmed_at IS NOT NULL THEN '✅ PASSED'
    ELSE '❌ FAILED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'

UNION ALL

SELECT
  'Public Users Table' as check_type,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM public.users
      WHERE email = 'masathomardforwork@gmail.com'
        AND role = 'trainer'
        AND is_active = true
    ) THEN '✅ PASSED'
    ELSE '❌ FAILED'
  END as status

UNION ALL

SELECT
  'Not Banned' as check_type,
  CASE
    WHEN banned_until IS NULL OR banned_until < NOW() THEN '✅ PASSED'
    ELSE '❌ FAILED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- All checks should show: ✅ PASSED
--
-- If any show ❌ FAILED:
-- 1. Email Confirmation FAILED: Run Step 1 UPDATE command again
-- 2. Public Users Table FAILED: Run Step 2 INSERT command again
-- 3. Not Banned FAILED: Run Step 4 UPDATE command again
-- ============================================================================

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- Your user account should be fully set up:
-- ✅ Email confirmed
-- ✅ User exists in public.users with role='trainer'
-- ✅ User is not banned
-- ✅ User is active
--
-- HOWEVER: This does NOT reset your password!
--
-- To reset password, you MUST:
-- 1. Go to Dashboard → Authentication → Users
-- 2. Click on your user: masathomardforwork@gmail.com
-- 3. Look for "Update User" button or "..." menu
-- 4. Set new password: Coach2025!
-- 5. Save
--
-- Then test login in your app with:
-- Email: masathomardforwork@gmail.com
-- Password: Coach2025!
-- ============================================================================
