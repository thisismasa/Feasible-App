-- ============================================================================
-- DIRECT PASSWORD UPDATE (For Development Only!)
-- ============================================================================
-- This updates the password hash directly in auth.users table
-- ONLY works if you have direct database access

-- WARNING: This is a WORKAROUND for development
-- For production, use proper password reset flow

-- ============================================================================
-- STEP 1: Generate password hash for "LeoNard007"
-- ============================================================================

-- Supabase uses bcrypt for password hashing
-- You cannot run this from SQL Editor directly

-- INSTEAD: Use Supabase Dashboard UI

-- ============================================================================
-- EASIEST METHOD: Supabase Dashboard UI (NO password reset email)
-- ============================================================================

-- 1. Open: https://supabase.com/dashboard
-- 2. Select project: "Flutter App, Feasible"
-- 3. Go to: Authentication → Users
-- 4. Find user: masathomardforwork@gmail.com
-- 5. Click the row (not the ... menu)
-- 6. On the right side panel, you'll see "Update User"
-- 7. Enter new password: LeoNard007
-- 8. Click "Update User"

-- This does NOT send an email - it updates the password immediately!

-- ============================================================================
-- ALTERNATIVE: Create a SQL function to update password
-- ============================================================================

-- Check if user exists first
SELECT
  id,
  email,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- If user exists but you still can't login, the issue is:
-- 1. Wrong password in database (fix: use Dashboard UI to update)
-- 2. Email not confirmed (fix: click "Confirm Email" in Dashboard)
-- 3. Account disabled (fix: check user status in Dashboard)

-- ============================================================================
-- If auth.users returns NO ROWS:
-- ============================================================================
-- Then the user only exists in public.users, not in auth.users
-- You need to CREATE the auth user:

-- 1. Go to Supabase Dashboard → Authentication → "Invite User" button
-- 2. Email: masathomardforwork@gmail.com
-- 3. Check "Auto Confirm User" checkbox
-- 4. Password: LeoNard007
-- 5. Click "Invite"

-- This creates the auth.users entry and links it to public.users automatically
