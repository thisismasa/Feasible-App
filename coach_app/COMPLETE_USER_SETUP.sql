-- ============================================================================
-- COMPLETE USER SETUP - FIXED VERSION
-- ============================================================================
-- This script:
-- 1. Adds all missing columns
-- 2. Confirms your email
-- 3. Adds you to public.users table
-- 4. Makes you ready to log in
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Add all missing columns to public.users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;

-- Step 2: Manually confirm email (skip clicking link)
UPDATE auth.users
SET email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com'
  AND email_confirmed_at IS NULL;

-- Step 3: Manually insert into public.users (complete what trigger should have done)
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

-- Step 4: Verify everything is set up correctly
-- Check auth.users
SELECT
  'auth.users' as table_name,
  email,
  CASE
    WHEN email_confirmed_at IS NOT NULL THEN '✅ EMAIL CONFIRMED'
    ELSE '❌ NOT CONFIRMED'
  END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- Check public.users
SELECT
  'public.users' as table_name,
  email,
  role,
  is_active,
  CASE
    WHEN role = 'trainer' AND is_active = true THEN '✅ READY TO LOG IN'
    ELSE '❌ NEEDS FIX'
  END as status
FROM public.users
WHERE email = 'masathomardforwork@gmail.com';

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- Query 1 (auth.users): Should show "✅ EMAIL CONFIRMED"
-- Query 2 (public.users): Should show "✅ READY TO LOG IN"
--
-- If both show green checkmarks, YOU'RE READY!
-- ============================================================================

-- ============================================================================
-- NOW YOU CAN LOG IN
-- ============================================================================
-- 1. Go to your Flutter app
-- 2. Click "Sign In" tab (NOT "Sign Up")
-- 3. Enter:
--    Email: masathomardforwork@gmail.com
--    Password: [the password you used during signup]
-- 4. Click "Sign In to Dashboard"
-- 5. Should successfully log in! ✅
--
-- Expected console output:
-- ✅ Database Service: REAL MODE
-- 🔐 Signing in user: masathomardforwork@gmail.com
-- ✅ User logged in successfully
-- 🔹 Dashboard mode: REAL
-- ✓ Dashboard loaded successfully
--
-- Dashboard should show:
-- - 0 clients (empty state)
-- - 0 sessions
-- - No demo data
-- - Clean slate! 🎯
-- ============================================================================
