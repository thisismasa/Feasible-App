-- ============================================
-- FIX NUTTAPON BOOKING ISSUE - AUTOMATIC FIX
-- ============================================
-- This will fix common package issues for Nuttapon
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Activate Nuttapon's packages
UPDATE client_packages
SET is_active = true
WHERE client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
);

-- STEP 2: Fix remaining_sessions (if NULL or 0)
UPDATE client_packages
SET remaining_sessions = COALESCE(total_sessions, 10)
WHERE client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
)
AND (remaining_sessions IS NULL OR remaining_sessions = 0);

-- STEP 3: Fix expiry_date (if NULL or expired)
UPDATE client_packages
SET expiry_date = CASE
  WHEN expiry_date IS NULL OR expiry_date < NOW() THEN
    NOW() + INTERVAL '90 days'
  ELSE
    expiry_date
  END
WHERE client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
)
AND (expiry_date IS NULL OR expiry_date < NOW());

-- STEP 4: Fix start_date (if NULL)
UPDATE client_packages
SET start_date = COALESCE(purchase_date, NOW())
WHERE client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
)
AND start_date IS NULL;

-- STEP 5: Fix package_id (if NULL or references inactive plan)
UPDATE client_packages cp
SET package_id = (
  SELECT id FROM packages
  WHERE is_active = true
  ORDER BY sessions
  LIMIT 1
)
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
)
AND (
  cp.package_id IS NULL
  OR NOT EXISTS (
    SELECT 1 FROM packages p
    WHERE p.id = cp.package_id AND p.is_active = true
  )
);

-- ============================================
-- VERIFICATION: Check if fixes worked
-- ============================================

-- Show Nuttapon's packages after fixes
SELECT
  'NUTTAPON PACKAGES - AFTER FIX' as section,
  cp.id,
  u.full_name as client_name,
  u.email,
  cp.package_name,
  cp.remaining_sessions,
  cp.total_sessions,
  cp.is_active as package_active,
  cp.start_date,
  cp.expiry_date,
  p.name as package_plan_name,
  p.is_active as plan_active,
  -- Validation checks
  CASE
    WHEN cp.is_active = false THEN '❌ Package inactive'
    WHEN cp.remaining_sessions IS NULL THEN '❌ No remaining sessions'
    WHEN cp.remaining_sessions = 0 THEN '❌ Zero sessions'
    WHEN cp.expiry_date < NOW() THEN '❌ Expired'
    WHEN p.id IS NULL THEN '❌ Package plan not found'
    WHEN p.is_active = false THEN '❌ Package plan inactive'
    ELSE '✅ READY TO BOOK'
  END as status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- Show summary
SELECT
  'FIX SUMMARY' as section,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE is_active = true) as active_packages,
  COUNT(*) FILTER (WHERE remaining_sessions > 0) as has_sessions,
  COUNT(*) FILTER (WHERE expiry_date > NOW()) as not_expired,
  COUNT(*) FILTER (
    WHERE is_active = true
    AND remaining_sessions > 0
    AND expiry_date > NOW()
    AND package_id IS NOT NULL
  ) as ready_to_book
FROM client_packages
WHERE client_id IN (
  SELECT id FROM users
  WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%'
);

-- ============================================
-- EXPECTED RESULT AFTER RUNNING
-- ============================================
-- ✅ All Nuttapon packages activated
-- ✅ Remaining sessions set (10 or total_sessions)
-- ✅ Expiry date extended by 90 days
-- ✅ Start date set to today
-- ✅ Package_id linked to active package plan
-- ✅ Status should show "✅ READY TO BOOK"
-- ============================================
