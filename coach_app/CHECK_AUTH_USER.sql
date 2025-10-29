-- ============================================================================
-- CHECK AUTH USER - masathmardforwork@gmail.com
-- ============================================================================
-- Diagnose login error: Invalid login credentials (400)
-- ============================================================================

-- Check if user exists in auth.users
SELECT
  '🔍 AUTH USER CHECK' as section,
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  created_at,
  updated_at,
  last_sign_in_at,
  raw_user_meta_data,
  CASE
    WHEN email_confirmed_at IS NULL THEN '❌ Email NOT confirmed'
    ELSE '✅ Email confirmed'
  END as email_status,
  CASE
    WHEN confirmed_at IS NULL THEN '❌ Account NOT confirmed'
    ELSE '✅ Account confirmed'
  END as account_status
FROM auth.users
WHERE email = 'masathmardforwork@gmail.com';

-- Check if user exists in public.users
SELECT
  '👤 PUBLIC USER CHECK' as section,
  id,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE email = 'masathmardforwork@gmail.com';

-- Check all auth users (to see if email is slightly different)
SELECT
  '📋 ALL AUTH USERS' as section,
  email,
  email_confirmed_at IS NOT NULL as confirmed,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 20;

-- Possible issues and fixes
SELECT
  '🔧 DIAGNOSIS & FIXES' as section,
  CASE
    WHEN NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'masathmardforwork@gmail.com')
    THEN '❌ User does not exist - Need to create account or check email spelling'

    WHEN EXISTS (
      SELECT 1 FROM auth.users
      WHERE email = 'masathmardforwork@gmail.com'
      AND email_confirmed_at IS NULL
    )
    THEN '⚠️ Email not confirmed - Need to confirm email or bypass confirmation'

    WHEN EXISTS (
      SELECT 1 FROM auth.users
      WHERE email = 'masathmardforwork@gmail.com'
      AND email_confirmed_at IS NOT NULL
    )
    THEN '✅ User exists and confirmed - Check password or try password reset'

    ELSE 'Unknown issue'
  END as diagnosis;

-- ============================================================================
-- POSSIBLE FIXES:
-- ============================================================================

-- FIX 1: If user exists but email not confirmed, confirm it:
-- UPDATE auth.users
-- SET email_confirmed_at = NOW()
-- WHERE email = 'masathmardforwork@gmail.com';

-- FIX 2: If user doesn't exist, check for similar emails:
-- SELECT email FROM auth.users
-- WHERE email LIKE '%masathomard%' OR email LIKE '%@gmail.com%';

-- FIX 3: Reset password (if user exists):
-- Use Supabase Dashboard > Authentication > Users > Find user > Send password reset

-- ============================================================================
