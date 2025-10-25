-- ============================================================================
-- FIX: Add Missing photo_url Column
-- ============================================================================
-- Error: "Could not find the 'photo_url' column of 'users' in the schema cache"
-- The trigger is trying to write to photo_url but the column doesn't exist
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Add the missing photo_url column
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Also add other commonly needed columns
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Make sure is_online column exists (from previous fix)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

-- Add last_seen column
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add preferences column
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;

-- Verify all columns exist
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name IN ('photo_url', 'avatar_url', 'is_online', 'last_seen', 'preferences', 'profile_image_url')
ORDER BY column_name;

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- ✅ photo_url column added
-- ✅ avatar_url column added
-- ✅ is_online column added
-- ✅ All required columns exist
--
-- NOW:
-- 1. Check your email: masathomardforwork@gmail.com
-- 2. Click the confirmation link from Supabase
-- 3. Your account will be activated
-- 4. Go back to app and try logging in
--
-- OR if you want to skip email confirmation:
-- Run this to manually confirm:
--
-- UPDATE auth.users
-- SET email_confirmed_at = NOW()
-- WHERE email = 'masathomardforwork@gmail.com';
--
-- Then the trigger should run successfully!
-- ============================================================================

-- Optional: Manually confirm the email now (skip email click)
UPDATE auth.users
SET email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND email_confirmed_at IS NULL;

-- Now manually insert into public.users if trigger failed
INSERT INTO public.users (
  id,
  email,
  full_name,
  phone,
  role,
  is_active,
  is_online,
  photo_url,
  avatar_url,
  profile_image_url,
  created_at,
  updated_at
)
SELECT
  id,
  email,
  COALESCE(raw_user_meta_data->>'full_name', 'masathomard'),
  COALESCE(raw_user_meta_data->>'phone', '0955352683'),
  'trainer',
  true,
  false,
  raw_user_meta_data->>'photo_url',
  raw_user_meta_data->>'avatar_url',
  raw_user_meta_data->>'avatar_url',
  created_at,
  NOW()
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  role = 'trainer',
  is_active = true,
  updated_at = NOW();

-- Verify user is now in both tables
SELECT
  'auth.users' as table_name,
  id::text,
  email,
  email_confirmed_at::text as confirmed_or_created,
  CASE
    WHEN email_confirmed_at IS NOT NULL THEN '✅ CONFIRMED'
    ELSE '❌ NOT CONFIRMED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com'

UNION ALL

SELECT
  'public.users' as table_name,
  id::text,
  email,
  created_at::text as confirmed_or_created,
  CASE
    WHEN role = 'trainer' AND is_active = true THEN '✅ READY'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- Expected:
-- auth.users: ✅ CONFIRMED
-- public.users: ✅ READY

-- ============================================================================
-- AFTER THIS SCRIPT
-- ============================================================================
-- Your user should be fully set up:
-- ✅ User exists in auth.users
-- ✅ Email is confirmed
-- ✅ User exists in public.users with role='trainer'
-- ✅ All required columns exist
--
-- NOW YOU CAN LOG IN:
-- 1. Go to your Flutter app
-- 2. Click "Sign In" tab
-- 3. Enter:
--    Email: masathomardforwork@gmail.com
--    Password: [the password you just set during signup]
-- 4. Click "Sign In to Dashboard"
-- 5. Should work! ✅
-- ============================================================================
