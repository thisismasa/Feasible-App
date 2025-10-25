-- ============================================================================
-- CHECK CLIENTS DATA
-- ============================================================================
-- Let's see what clients exist and their relationships
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Step 1: Show all users (should include your trainer and clients)
SELECT
  id,
  email,
  full_name,
  phone,
  role,
  is_active,
  created_at
FROM users
ORDER BY created_at DESC;

-- Step 2: Show trainer-client relationships
SELECT
  tc.id,
  tc.trainer_id,
  t.full_name as trainer_name,
  t.email as trainer_email,
  tc.client_id,
  c.full_name as client_name,
  c.email as client_email,
  tc.is_active,
  tc.assigned_at
FROM trainer_clients tc
LEFT JOIN users t ON tc.trainer_id = t.id
LEFT JOIN users c ON tc.client_id = c.id
ORDER BY tc.assigned_at DESC;

-- Step 3: Show client packages (if any exist)
SELECT
  cp.id,
  cp.client_id,
  c.full_name as client_name,
  c.email as client_email,
  cp.package_id,
  cp.status,
  cp.created_at
FROM client_packages cp
LEFT JOIN users c ON cp.client_id = c.id
ORDER BY cp.created_at DESC
LIMIT 10;

-- ============================================================================
-- This will show:
-- 1. All users in the system (trainer + clients)
-- 2. Which clients are assigned to which trainers
-- 3. Which packages clients have (probably empty for new clients)
-- ============================================================================
