-- ============================================================================
-- DELETE USER AND START FRESH
-- ============================================================================
-- This script completely removes the user: masathomardforwork@gmail.com
-- so you can register a new account from scratch
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- ⚠️ WARNING: This will permanently delete all data for this user!
-- Make sure you want to do this before running!

-- Step 1: Delete from public.users table first (due to foreign key constraints)
DELETE FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 2: Delete from auth.users (main authentication table)
DELETE FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Step 3: Verify user is deleted
SELECT
  'auth.users' as table_name,
  COUNT(*) as remaining_records
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'

UNION ALL

SELECT
  'public.users' as table_name,
  COUNT(*) as remaining_records
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Expected: Both should show 0 remaining records

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- ✅ User masathomardforwork@gmail.com is completely deleted
-- ✅ You can now register fresh via the app
--
-- NEXT STEPS:
-- 1. Go to your Flutter app
-- 2. Click "Sign Up" tab (NOT "Sign In")
-- 3. Enter:
--    - Email: masathomardforwork@gmail.com
--    - Password: Coach2025! (or your choice)
--    - Full Name: Masatho Mard (or your name)
-- 4. Click "Sign Up" or "Create Account"
-- 5. The app should create your account automatically
-- 6. You should be logged in immediately
--
-- The trigger we set up (COMPLETE_SETUP_FOR_ANY_USER.sql) will automatically:
-- ✅ Add you to public.users table
-- ✅ Set your role to 'trainer'
-- ✅ Mark your account as active
-- ✅ Confirm your email automatically
--
-- Result: Clean, working account! 🎉
-- ============================================================================
