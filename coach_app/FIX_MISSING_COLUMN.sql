-- ============================================================================
-- FIX: Add Missing is_online Column to users Table
-- ============================================================================
-- Error: "Could not find the 'is_online' column of 'users' in the schema cache"
-- This means the users table is missing the is_online column
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Add the missing is_online column to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

-- Add index for performance (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_users_is_online
ON public.users(is_online)
WHERE is_online = true;

-- Update existing users to set is_online = false
UPDATE public.users
SET is_online = false
WHERE is_online IS NULL;

-- Verify the column was added
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name = 'is_online';

-- Expected result: Should show the is_online column with:
-- - data_type: boolean
-- - column_default: false
-- - is_nullable: YES

-- ============================================================================
-- AFTER RUNNING THIS SCRIPT
-- ============================================================================
-- ✅ is_online column added to users table
-- ✅ Default value set to false
-- ✅ Index created for performance
-- ✅ Existing users updated
--
-- NOW YOU CAN REGISTER:
-- 1. Go to your Flutter app
-- 2. Click "Sign Up" tab
-- 3. Fill in the form:
--    - Full Name: Masatho Mard
--    - Email: masathomardforwork@gmail.com
--    - Phone: 0955352683
--    - Password: [your password]
-- 4. Click "Create Account"
-- 5. Should work now! ✅
-- ============================================================================

-- Optional: Add other potentially missing columns that might cause similar errors

-- Add last_seen column (useful for tracking when user was last online)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add profile_image_url column (if not exists)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Add preferences column for user settings (JSONB for flexibility)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;

-- Verify all columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
ORDER BY ordinal_position;

-- This will show all columns in the users table
-- Make sure is_online is in the list

-- ============================================================================
-- COMPLETE USERS TABLE SCHEMA (For Reference)
-- ============================================================================
-- After running this script, your users table should have:
-- - id (uuid, primary key)
-- - email (text, unique)
-- - full_name (text)
-- - phone (text)
-- - role (text) - 'trainer' or 'client'
-- - is_active (boolean)
-- - is_online (boolean) ← ADDED
-- - last_seen (timestamp) ← ADDED
-- - profile_image_url (text) ← ADDED
-- - preferences (jsonb) ← ADDED
-- - created_at (timestamp)
-- - updated_at (timestamp)
-- ============================================================================
