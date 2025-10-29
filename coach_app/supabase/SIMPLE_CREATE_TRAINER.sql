-- ============================================================================
-- SIMPLE: Create Trainer Account for masathomardforwork@gmail.com
-- ============================================================================
-- IMPORTANT: You must create the auth user FIRST in Supabase Dashboard!
-- Go to: Authentication → Users → Add user
-- Email: masathomardforwork@gmail.com
-- Password: [your password]
-- CHECK "Auto Confirm User"
-- Then run this SQL
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get user ID from auth.users
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = 'masathomardforwork@gmail.com';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION '❌ User not found! Please create the user in Supabase Dashboard first (Authentication → Users → Add user)';
  END IF;

  -- Create or update user profile
  INSERT INTO users (id, email, full_name, phone, role, created_at, updated_at)
  VALUES (
    v_user_id,
    'masathomardforwork@gmail.com',
    'Masathomard',
    '',
    'trainer',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET role = 'trainer',
      updated_at = NOW();

  RAISE NOTICE '✅ SUCCESS! Trainer account is ready!';
  RAISE NOTICE 'Email: masathomardforwork@gmail.com';
  RAISE NOTICE 'Role: trainer';
  RAISE NOTICE 'You can now sign in!';
END $$;

-- Verify the account was created
SELECT
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  au.confirmed_at as email_confirmed
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.email = 'masathomardforwork@gmail.com';
