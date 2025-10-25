-- ============================================================================
-- CHECK if user exists in auth.users (authentication table)
-- ============================================================================

-- Check auth.users table
SELECT
  id,
  email,
  email_confirmed_at,
  encrypted_password IS NOT NULL as has_password,
  created_at,
  last_sign_in_at,
  confirmation_sent_at
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- The issue might be:
-- 1. User exists in public.users but NOT in auth.users (account not properly created)
-- 2. User exists in auth.users but password is different from "LeoNard007"
-- 3. Email not confirmed (email_confirmed_at is NULL)

-- If the query above returns NO ROWS, then the user was never created in auth
-- In that case, we need to create it via Supabase Dashboard

-- ============================================================================
-- INSTRUCTIONS based on results:
-- ============================================================================

-- IF NO ROWS RETURNED:
-- → User only exists in public.users, not in auth.users
-- → Go to Supabase Dashboard → Authentication → "Invite User"
-- → Email: masathomardforwork@gmail.com
-- → Password: LeoNard007
-- → This will create the auth entry

-- IF ROW RETURNED but email_confirmed_at IS NULL:
-- → Email needs to be confirmed
-- → Go to Supabase Dashboard → Authentication → Users
-- → Find user → Click "..." → "Confirm Email"

-- IF ROW RETURNED and email_confirmed_at HAS VALUE:
-- → Password is wrong in database
-- → Go to Supabase Dashboard → Authentication → Users
-- → Find user → Click "..." → "Reset Password"
-- → Set to: LeoNard007
