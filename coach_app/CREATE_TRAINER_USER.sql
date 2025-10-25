-- ============================================================================
-- CREATE TRAINER USER FOR COACH APP
-- ============================================================================
-- This script creates a trainer user account and sets up all necessary data
-- Run this in Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Create the user in auth.users
-- NOTE: Supabase Auth doesn't allow direct INSERT into auth.users via SQL
-- You MUST create the user through the Supabase Dashboard UI:
--
-- Go to: Authentication → Users → Add User
-- Enter:
--   - Email: masathomardforwork@gmail.com
--   - Password: [your chosen password]
--   - Auto Confirm User: ✅ CHECK THIS BOX
-- Click: "Create User"
--
-- After creating via UI, the trigger will automatically add to public.users
-- If it doesn't work, uncomment and run the manual insert below:

-- ============================================================================
-- MANUAL BACKUP: Add to public.users table (if trigger didn't work)
-- ============================================================================
-- First, get your user ID by running this query:
-- SELECT id, email FROM auth.users WHERE email = 'masathomardforwork@gmail.com';
-- Copy the ID and replace 'YOUR-USER-UUID-HERE' below:

/*
INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
VALUES (
  'YOUR-USER-UUID-HERE',  -- Replace with actual UUID from auth.users!
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
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if user exists in auth.users
SELECT
  id,
  email,
  email_confirmed_at,
  created_at,
  updated_at
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Check if user exists in public.users
SELECT
  id,
  email,
  full_name,
  role,
  is_active,
  created_at
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Check if trigger exists and is active
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- After creating user via Dashboard and running verification queries:
--
-- Query 1 (auth.users): Should return 1 row
--   - id: [some UUID]
--   - email: masathomardforwork@gmail.com
--   - email_confirmed_at: [timestamp] (not null)
--   - created_at: [timestamp]
--
-- Query 2 (public.users): Should return 1 row
--   - id: [same UUID as auth.users]
--   - email: masathomardforwork@gmail.com
--   - full_name: Masatho Mard (or your name)
--   - role: trainer
--   - is_active: true
--
-- Query 3 (trigger check): Should return 1 row showing the trigger exists
--
-- If Query 2 returns NO rows, the trigger didn't fire.
-- In that case:
-- 1. Copy the UUID from Query 1 result
-- 2. Uncomment the INSERT statement above
-- 3. Replace 'YOUR-USER-UUID-HERE' with the actual UUID
-- 4. Run the INSERT statement
-- ============================================================================

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- If user already exists but login fails, try confirming the email:
/*
UPDATE auth.users
SET email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND email_confirmed_at IS NULL;
*/

-- If user is locked or banned:
/*
UPDATE auth.users
SET banned_until = NULL,
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com';
*/

-- If you need to reset password (generate temporary reset):
/*
-- NOTE: This doesn't actually reset the password via SQL
-- You MUST use: Authentication → Users → [Your User] → Send Password Reset Email
-- Or use "Forgot Password?" in the app
*/

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- 1. ✅ User should exist in both auth.users and public.users
-- 2. ✅ Email should be confirmed
-- 3. ✅ Role should be 'trainer'
-- 4. ✅ User can now log in to the app with:
--       Email: masathomardforwork@gmail.com
--       Password: [the password you set when creating user]
-- 5. ✅ Dashboard will show empty state (0 clients, 0 sessions)
-- 6. ✅ App will be in REAL mode (not DEMO)
-- ============================================================================
