-- ============================================================================
-- MAKE ME A TRAINER - Run this AFTER signing in with Google
-- ============================================================================

-- This will make masathomardforwork@gmail.com a trainer
UPDATE users
SET role = 'trainer',
    updated_at = NOW()
WHERE email = 'masathomardforwork@gmail.com';

-- Verify it worked
SELECT
  id,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE email = 'masathomardforwork@gmail.com';

-- You should see: role = 'trainer'
