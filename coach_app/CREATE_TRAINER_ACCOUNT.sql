-- ============================================================================
-- CREATE TRAINER ACCOUNT - masathmardforwork@gmail.com
-- ============================================================================
-- User doesn't exist, let's create it
-- ============================================================================

-- First, check for similar emails to avoid duplicates
SELECT
  '🔍 SIMILAR EMAILS CHECK' as section,
  email,
  created_at,
  CASE
    WHEN email LIKE '%masathomard%' THEN '⚠️ Similar to masathmardforwork@gmail.com'
    WHEN email LIKE '%masath%' THEN '⚠️ Contains masath'
    ELSE 'Different'
  END as similarity
FROM auth.users
WHERE email LIKE '%masath%' OR email LIKE '%@gmail.com%'
ORDER BY email;

-- Check public.users table too
SELECT
  '👤 PUBLIC USERS - SIMILAR' as section,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE email LIKE '%masath%'
ORDER BY email;

-- Show all trainer accounts
SELECT
  '🎯 ALL TRAINERS' as section,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  au.email_confirmed_at IS NOT NULL as auth_confirmed
FROM users u
LEFT JOIN auth.users au ON u.email = au.email
WHERE u.role = 'trainer'
ORDER BY u.created_at DESC;

-- ============================================================================
-- CREATE THE TRAINER ACCOUNT
-- ============================================================================

-- Step 1: Create auth user (this is the Supabase-safe way)
-- Note: We can't directly INSERT into auth.users, but we can use sign-up flow
-- For now, let's create in public.users and set up the mapping

-- Step 2: Check if a trainer ID exists
DO $$
DECLARE
  v_trainer_id UUID;
  v_trainer_exists BOOLEAN;
BEGIN
  -- Check if trainer already exists in public.users
  SELECT id INTO v_trainer_id
  FROM users
  WHERE email = 'masathmardforwork@gmail.com'
  LIMIT 1;

  IF v_trainer_id IS NULL THEN
    -- Create new trainer user
    INSERT INTO users (
      id,
      email,
      full_name,
      role,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      'masathmardforwork@gmail.com',
      'Masathomard',
      'trainer',
      NOW(),
      NOW()
    )
    RETURNING id INTO v_trainer_id;

    RAISE NOTICE '✅ Created trainer in public.users: %', v_trainer_id;
  ELSE
    RAISE NOTICE '⚠️ Trainer already exists in public.users: %', v_trainer_id;
  END IF;

END $$;

-- Step 3: Create auth user with confirmed email
-- This creates the user and confirms their email immediately
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  (SELECT id FROM users WHERE email = 'masathmardforwork@gmail.com'),
  'authenticated',
  'authenticated',
  'masathmardforwork@gmail.com',
  crypt('LeoNard007', gen_salt('bf')), -- User's actual password: LeoNard007
  NOW(), -- Email confirmed immediately
  NULL,
  NULL,
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Masathomard","role":"trainer"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = NOW(),
  updated_at = NOW();

-- Step 4: Verify creation
SELECT
  '✅ ACCOUNT CREATED' as section,
  u.id,
  u.email,
  u.full_name,
  u.role as public_role,
  au.email as auth_email,
  au.email_confirmed_at IS NOT NULL as confirmed,
  'Password: LeoNard007' as default_password
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'masathmardforwork@gmail.com';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT
  '📋 FINAL STATUS' as section,
  EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'masathmardforwork@gmail.com'
  ) as auth_user_exists,
  EXISTS (
    SELECT 1 FROM users WHERE email = 'masathmardforwork@gmail.com' AND role = 'trainer'
  ) as public_user_exists,
  EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'masathmardforwork@gmail.com' AND email_confirmed_at IS NOT NULL
  ) as email_confirmed,
  CASE
    WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'masathmardforwork@gmail.com' AND email_confirmed_at IS NOT NULL)
    THEN '✅ Ready to login with: masathmardforwork@gmail.com / LeoNard007'
    ELSE '❌ Still has issues'
  END as status;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- auth_user_exists: true
-- public_user_exists: true
-- email_confirmed: true
-- status: ✅ Ready to login with: masathmardforwork@gmail.com / LeoNard007
-- ============================================================================

-- ============================================================================
-- AFTER RUNNING THIS:
-- ============================================================================
-- 1. Login credentials:
--    Email: masathmardforwork@gmail.com
--    Password: LeoNard007
--
-- 2. Change password immediately after first login!
--
-- 3. If login still fails, try:
--    - Clear browser cache
--    - Use incognito mode
--    - Check Supabase Auth settings
-- ============================================================================
