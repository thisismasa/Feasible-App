-- ============================================================================
-- CHECK USER AUTHENTICATION
-- ============================================================================

-- Check if user exists in auth.users
SELECT
  id,
  email,
  email_confirmed_at,
  created_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Check if user exists in public.users
SELECT
  id,
  email,
  full_name,
  role,
  created_at
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Check all trainers
SELECT
  id,
  email,
  full_name,
  role
FROM public.users
WHERE role = 'trainer';
