-- ============================================
-- INVESTIGATE NUTTAPON BOOKING FAILURE
-- ============================================
-- Run this in Supabase SQL Editor to diagnose the issue
-- ============================================

-- 1. Find Nuttapon's user record
SELECT
  'NUTTAPON USER INFO' as section,
  id,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE LOWER(full_name) LIKE '%nuttapon%' OR LOWER(email) LIKE '%nuttapon%';

-- 2. Check Nuttapon's client packages (ALL fields)
SELECT
  'NUTTAPON PACKAGES - DETAILED' as section,
  cp.id as package_id,
  cp.client_id,
  cp.package_id as package_plan_id,
  cp.package_name,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.used_sessions,
  cp.is_active as package_is_active,
  cp.start_date,
  cp.expiry_date,
  cp.purchase_date,
  cp.price_paid,
  cp.created_at,
  -- Check if expired
  CASE
    WHEN cp.expiry_date < NOW() THEN '❌ EXPIRED'
    WHEN cp.expiry_date IS NULL THEN '⚠️ NO EXPIRY DATE'
    ELSE '✅ VALID'
  END as expiry_status,
  -- Check remaining sessions
  CASE
    WHEN cp.remaining_sessions IS NULL THEN '❌ NULL'
    WHEN cp.remaining_sessions = 0 THEN '❌ NO SESSIONS LEFT'
    WHEN cp.remaining_sessions > 0 THEN '✅ HAS SESSIONS'
    ELSE '⚠️ NEGATIVE'
  END as sessions_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- 3. Check if package_id references a valid package plan
SELECT
  'PACKAGE PLAN VALIDATION' as section,
  cp.id as client_package_id,
  cp.package_id as referenced_package_id,
  p.id as actual_package_id,
  p.name as package_name,
  p.is_active as plan_is_active,
  CASE
    WHEN p.id IS NULL THEN '❌ PACKAGE PLAN NOT FOUND'
    WHEN p.is_active = false THEN '❌ PACKAGE PLAN INACTIVE'
    ELSE '✅ VALID'
  END as validation_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- 4. Check all package plans (to see what's available)
SELECT
  'ALL AVAILABLE PACKAGE PLANS' as section,
  id,
  name,
  sessions,
  price,
  is_active,
  created_at
FROM packages
ORDER BY is_active DESC, name;

-- 5. Check recent bookings for Nuttapon
SELECT
  'NUTTAPON BOOKING HISTORY' as section,
  b.id as booking_id,
  b.session_date,
  b.status,
  b.client_package_id,
  b.created_at
FROM bookings b
JOIN users u ON b.client_id = u.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%'
ORDER BY b.created_at DESC
LIMIT 5;

-- ============================================
-- DIAGNOSIS SUMMARY
-- ============================================
-- After running, check:
-- 1. Is package is_active = true?
-- 2. Is package expiry_date in the future?
-- 3. Does package have remaining_sessions > 0?
-- 4. Does package_id reference a valid package plan?
-- 5. Is the package plan is_active = true?
-- ============================================
