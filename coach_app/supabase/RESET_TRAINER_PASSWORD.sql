-- ============================================================================
-- TEMPORARY: Reset password for testing (NOT FOR PRODUCTION!)
-- ============================================================================
-- This is ONLY for development/testing
-- For production with 100-1000 trainers, use proper password reset flow

-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Find user: masathomardforwork@gmail.com
-- 3. Click "..." (three dots) → "Reset Password"
-- 4. Set new password: LeoNard007 (or any password you want)

-- OR use the Supabase dashboard to send a password reset email

-- For production scale (100-1000 trainers), you need:
-- 1. Email-based password reset flow
-- 2. Self-service trainer onboarding
-- 3. Admin panel to manage trainer accounts

-- Check current user status
SELECT
  id,
  email,
  email_confirmed_at,
  last_sign_in_at,
  created_at
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- PRODUCTION-READY: Trainer Account Management Functions
-- ============================================================================

-- Function to check if trainer can login
CREATE OR REPLACE FUNCTION check_trainer_status(p_email TEXT)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  can_login BOOLEAN,
  reason TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.full_name,
    u.role,
    CASE
      WHEN au.email_confirmed_at IS NULL THEN FALSE
      WHEN u.role != 'trainer' THEN FALSE
      ELSE TRUE
    END as can_login,
    CASE
      WHEN au.email_confirmed_at IS NULL THEN 'Email not confirmed'
      WHEN u.role != 'trainer' THEN 'Not a trainer account'
      ELSE 'OK'
    END as reason
  FROM public.users u
  LEFT JOIN auth.users au ON au.id = u.id
  WHERE u.email = p_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check current trainer
SELECT * FROM check_trainer_status('masathomardforwork@gmail.com');

-- ============================================================================
-- For admin use: List all trainers and their login status
-- ============================================================================

SELECT
  u.id,
  u.email,
  u.full_name,
  au.email_confirmed_at,
  au.last_sign_in_at,
  CASE
    WHEN au.email_confirmed_at IS NULL THEN '❌ Email not confirmed'
    WHEN au.last_sign_in_at IS NULL THEN '⚠️ Never logged in'
    ELSE '✅ Active'
  END as status
FROM public.users u
LEFT JOIN auth.users au ON au.id = u.id
WHERE u.role = 'trainer'
ORDER BY u.created_at DESC;
