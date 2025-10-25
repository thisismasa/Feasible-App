-- ============================================================================
-- DELETE TEST USERS
-- ============================================================================
-- This will show and delete test/demo users to allow fresh client creation
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Show all users EXCEPT your trainer account
SELECT
  id,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE email != 'masathomardforwork@gmail.com'
ORDER BY created_at DESC;

-- Step 2: Delete all users EXCEPT your trainer account
-- (This removes old test clients so you can add them fresh)
DELETE FROM users
WHERE email != 'masathomardforwork@gmail.com';

-- Step 3: Verify only your trainer account remains
SELECT
  COUNT(*) as remaining_users,
  CASE
    WHEN COUNT(*) = 1 THEN '✅ ONLY YOUR TRAINER ACCOUNT REMAINS'
    ELSE '❌ MULTIPLE USERS STILL EXIST'
  END as status
FROM users;

-- Step 4: Show your trainer account to confirm it's safe
SELECT
  email,
  full_name,
  role,
  is_active
FROM users
WHERE email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- remaining_users: 1
-- status: ✅ ONLY YOUR TRAINER ACCOUNT REMAINS
-- email: masathomardforwork@gmail.com
--
-- NOW YOU CAN ADD NEW CLIENTS WITH ANY EMAIL!
-- ============================================================================
