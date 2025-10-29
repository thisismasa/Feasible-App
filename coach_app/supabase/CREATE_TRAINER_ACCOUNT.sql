-- ============================================================================
-- CREATE TRAINER ACCOUNT FOR masathomardforwork@gmail.com
-- ============================================================================
-- This script creates a trainer account directly in Supabase
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Step 1: Create auth user (this requires admin access)
-- You need to do this through Supabase Dashboard instead:
-- 1. Go to: https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/auth/users
-- 2. Click "Add user" → "Create new user"
-- 3. Email: masathomardforwork@gmail.com
-- 4. Password: [Set a strong password]
-- 5. Check "Auto Confirm User" (so you don't need to verify email)
-- 6. Click "Create user"

-- After creating the auth user, copy the UUID from the user list, then run this:

-- Step 2: Create user profile in public.users table
-- Replace 'YOUR_USER_ID_HERE' with the UUID from Supabase Auth Users page

DO $$
DECLARE
  v_user_id UUID;
  v_user_exists BOOLEAN;
BEGIN
  -- Check if user already exists by email
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = 'masathomardforwork@gmail.com';

  IF v_user_id IS NULL THEN
    RAISE NOTICE '❌ User not found in auth.users. Please create the user in Supabase Dashboard first.';
    RAISE NOTICE '   Go to: Authentication → Users → Add user';
    RAISE NOTICE '   Email: masathomardforwork@gmail.com';
    RAISE NOTICE '   Then run this script again.';
  ELSE
    RAISE NOTICE '✓ Found user ID: %', v_user_id;

    -- Check if profile exists
    SELECT EXISTS(
      SELECT 1 FROM users WHERE id = v_user_id
    ) INTO v_user_exists;

    IF v_user_exists THEN
      RAISE NOTICE '✓ User profile already exists';

      -- Update role to trainer if it's not already
      UPDATE users
      SET role = 'trainer',
          updated_at = NOW()
      WHERE id = v_user_id
        AND role != 'trainer';

      IF FOUND THEN
        RAISE NOTICE '✓ Updated user role to trainer';
      END IF;
    ELSE
      -- Create user profile
      INSERT INTO users (
        id,
        email,
        full_name,
        phone,
        role,
        created_at,
        updated_at
      ) VALUES (
        v_user_id,
        'masathomardforwork@gmail.com',
        'Masathomard', -- Change this to your actual name
        '', -- Add phone if needed
        'trainer',
        NOW(),
        NOW()
      );

      RAISE NOTICE '✓ Created user profile as trainer';
    END IF;

    RAISE NOTICE '🎉 Trainer account ready!';
    RAISE NOTICE '   Email: masathomardforwork@gmail.com';
    RAISE NOTICE '   Role: trainer';
    RAISE NOTICE '   User ID: %', v_user_id;
    RAISE NOTICE '   You can now sign in with this account.';
  END IF;
END $$;

-- Show final user info
SELECT
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  au.confirmed_at,
  au.last_sign_in_at
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- ALTERNATIVE: Use Google Sign-In Instead
-- ============================================================================
-- If you prefer to use Google Sign-In:
-- 1. Open the app
-- 2. Click "Continue with Google" button
-- 3. Sign in with masathomardforwork@gmail.com
-- 4. The account will be created automatically
-- 5. Then run this to make it a trainer:

/*
UPDATE users
SET role = 'trainer'
WHERE email = 'masathomardforwork@gmail.com';
*/
