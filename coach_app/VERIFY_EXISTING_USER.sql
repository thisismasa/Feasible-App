-- ============================================================================
-- VERIFY EXISTING USER IN SUPABASE
-- ============================================================================
-- Your user exists in auth.users with:
-- Email: masathomardforwork@gmail.com
-- UID: 797fb4f4-b568-407e-aea4-57c167862cb6
-- Created: Sep 23, 2025
-- Last sign in: Sep 23, 2025
--
-- Let's verify everything is set up correctly
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Query 1: Check auth.users (should return 1 row)
SELECT
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at,
  raw_user_meta_data
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Query 2: Check public.users (should return 1 row)
SELECT
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Query 3: If Query 2 returns NO rows, add user to public.users
-- Replace the UID below with: 797fb4f4-b568-407e-aea4-57c167862cb6
INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
VALUES (
  '797fb4f4-b568-407e-aea4-57c167862cb6',  -- Your actual UID
  'masathomardforwork@gmail.com',
  'Masatho Mard',  -- Change to your actual name
  'trainer',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = 'trainer',
  is_active = true,
  updated_at = NOW();

-- Query 4: Verify user was added to public.users
SELECT
  id,
  email,
  full_name,
  role,
  is_active
FROM public.users
WHERE id = '797fb4f4-b568-407e-aea4-57c167862cb6';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- Query 1: Should show your user from auth.users ✅
-- Query 2: Should show your user from public.users
--   - If NO rows: The trigger didn't fire, run Query 3
--   - If 1 row: Everything is good! ✅
-- Query 3: Inserts your user into public.users
-- Query 4: Confirms user is now in public.users ✅
-- ============================================================================

-- Query 5: Check if email is confirmed
SELECT
  id,
  email,
  email_confirmed_at,
  CASE
    WHEN email_confirmed_at IS NULL THEN '❌ NOT CONFIRMED'
    ELSE '✅ CONFIRMED'
  END as confirmation_status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Query 6: If email is NOT confirmed, force confirm it
UPDATE auth.users
SET email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND email_confirmed_at IS NULL;

-- Query 7: Verify email is now confirmed
SELECT
  email,
  email_confirmed_at,
  CASE
    WHEN email_confirmed_at IS NULL THEN '❌ NOT CONFIRMED'
    ELSE '✅ CONFIRMED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- TROUBLESHOOTING: Check password
-- ============================================================================
-- If you're getting "Invalid login credentials", it might be:
-- 1. Wrong password
-- 2. Email not confirmed

-- You CANNOT see or check passwords in Supabase (they're encrypted)
-- To reset password:
-- 1. Go to: Authentication → Users in Supabase Dashboard
-- 2. Click on your user: masathomardforwork@gmail.com
-- 3. Click: "Send Password Recovery Email"
-- 4. Or click: "Update User" → Set new password directly

-- ============================================================================
-- AFTER RUNNING QUERIES 1-7
-- ============================================================================
-- 1. ✅ User exists in auth.users
-- 2. ✅ User exists in public.users with role='trainer'
-- 3. ✅ Email is confirmed
-- 4. ✅ Ready to log in!
--
-- If still getting "Invalid login credentials":
-- → Password is wrong! Reset it via Dashboard:
--    Authentication → Users → Your User → "Update User" → Set new password
-- ============================================================================
