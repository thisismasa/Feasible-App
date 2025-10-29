-- ============================================
-- VERIFY NUTTAPON FIX - TEST IF BOOKING WORKS
-- ============================================
-- Run this to confirm Nuttapon can now book
-- ============================================

-- 1. Check Nuttapon's package status after fix
SELECT
  '✅ PACKAGE STATUS AFTER FIX' as section,
  u.full_name,
  u.email,
  cp.id as package_id,
  cp.package_name,
  cp.is_active,
  cp.remaining_sessions,
  cp.total_sessions,
  cp.start_date,
  cp.expiry_date,
  p.name as package_plan_name,
  p.is_active as plan_is_active,
  -- Final validation
  CASE
    WHEN cp.is_active = false THEN '❌ Package still inactive'
    WHEN cp.remaining_sessions IS NULL THEN '❌ No remaining sessions set'
    WHEN cp.remaining_sessions <= 0 THEN '❌ No sessions left'
    WHEN cp.expiry_date < NOW() THEN '❌ Package expired'
    WHEN cp.package_id IS NULL THEN '❌ No package plan linked'
    WHEN p.id IS NULL THEN '❌ Package plan not found'
    WHEN p.is_active = false THEN '❌ Package plan inactive'
    ELSE '✅ READY TO BOOK!'
  END as booking_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- 2. Simulate booking validation check
SELECT
  '🧪 BOOKING VALIDATION TEST' as section,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM client_packages cp
      JOIN users u ON cp.client_id = u.id
      LEFT JOIN packages p ON cp.package_id = p.id
      WHERE (LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%')
        AND cp.is_active = true
        AND cp.remaining_sessions > 0
        AND cp.expiry_date > NOW()
        AND p.is_active = true
    ) THEN '✅ PASS - Nuttapon can book!'
    ELSE '❌ FAIL - Still has issues'
  END as validation_result;

-- 3. Show detailed package info
SELECT
  '📋 DETAILED PACKAGE INFO' as section,
  cp.id,
  cp.package_name,
  cp.is_active as "Package Active?",
  cp.remaining_sessions as "Sessions Left",
  cp.total_sessions as "Total Sessions",
  cp.used_sessions as "Sessions Used",
  cp.start_date as "Valid From",
  cp.expiry_date as "Valid Until",
  CASE
    WHEN cp.expiry_date > NOW() THEN
      EXTRACT(DAY FROM (cp.expiry_date - NOW())) || ' days left'
    ELSE 'EXPIRED'
  END as "Days Remaining",
  p.name as "Package Plan",
  p.is_active as "Plan Active?",
  p.price as "Plan Price"
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- 4. Check if booking function would accept this package
SELECT
  '🔍 BOOKING FUNCTION CHECK' as section,
  cp.id as package_id,
  -- All conditions that booking function checks
  (cp.is_active = true) as "is_active ✓",
  (cp.remaining_sessions > 0) as "has_sessions ✓",
  (cp.expiry_date > NOW()) as "not_expired ✓",
  (cp.package_id IS NOT NULL) as "has_plan_id ✓",
  (p.is_active = true) as "plan_active ✓",
  -- Overall result
  CASE
    WHEN cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
      AND p.is_active = true
    THEN '✅ ALL CHECKS PASS'
    ELSE '❌ SOME CHECKS FAIL'
  END as result
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- 5. Try to book a test session (simulation only - no actual booking)
SELECT
  '📅 BOOKING SIMULATION' as section,
  u.full_name as client_name,
  cp.package_name,
  NOW() + INTERVAL '1 day' as proposed_booking_date,
  cp.remaining_sessions as sessions_before_booking,
  cp.remaining_sessions - 1 as sessions_after_booking,
  CASE
    WHEN cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW() + INTERVAL '1 day'
      AND p.is_active = true
    THEN '✅ BOOKING WOULD SUCCEED'
    ELSE '❌ BOOKING WOULD FAIL'
  END as booking_result
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- ============================================
-- ✅ EXPECTED RESULTS IF FIX WORKED
-- ============================================
-- Section 1: booking_status = "✅ READY TO BOOK!"
-- Section 2: validation_result = "✅ PASS - Nuttapon can book!"
-- Section 3: Shows all package details with valid dates
-- Section 4: result = "✅ ALL CHECKS PASS"
-- Section 5: booking_result = "✅ BOOKING WOULD SUCCEED"
-- ============================================
