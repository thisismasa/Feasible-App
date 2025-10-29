-- ============================================================================
-- COMPREHENSIVE DATABASE DIAGNOSIS AND FIX
-- ============================================================================
-- This script will diagnose and fix all package assignment issues
-- ============================================================================

\echo '========================================';
\echo '  STEP 1: Check client_packages table structure';
\echo '========================================';

-- Check if status column exists
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'client_packages'
  AND column_name IN ('status', 'remaining_sessions', 'total_sessions', 'price_paid')
ORDER BY ordinal_position;

\echo '';
\echo '========================================';
\echo '  STEP 2: Current state of all client packages';
\echo '========================================';

-- Show all client packages with their status
SELECT
  cp.id,
  u.full_name as client_name,
  u.email as client_email,
  cp.package_id,
  cp.status,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.price_paid,
  cp.purchase_date,
  cp.expiry_date,
  CASE
    WHEN cp.status IS NULL THEN '❌ STATUS IS NULL'
    WHEN cp.status != 'active' THEN '⚠️ STATUS: ' || cp.status
    WHEN cp.remaining_sessions IS NULL THEN '❌ REMAINING_SESSIONS IS NULL'
    WHEN cp.remaining_sessions <= 0 THEN '⚠️ NO SESSIONS LEFT'
    WHEN cp.expiry_date < NOW() THEN '⚠️ EXPIRED'
    ELSE '✅ LOOKS GOOD'
  END as diagnosis
FROM client_packages cp
LEFT JOIN users u ON cp.client_id = u.id
ORDER BY cp.created_at DESC;

\echo '';
\echo '========================================';
\echo '  STEP 3: Check for orphaned packages';
\echo '========================================';

-- Find client_packages with missing package references
SELECT
  cp.id as client_package_id,
  cp.client_id,
  cp.package_id,
  '❌ PACKAGE DOES NOT EXIST IN packages TABLE!' as issue
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id
WHERE p.id IS NULL;

\echo '';
\echo '========================================';
\echo '  STEP 4: Applying fixes...';
\echo '========================================';

-- Fix 1: Add status column if it doesn't exist
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- Fix 2: Set status to 'active' for NULL values
UPDATE client_packages
SET status = 'active'
WHERE status IS NULL;

-- Fix 3: Add remaining_sessions if missing
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS remaining_sessions INTEGER DEFAULT 0;

-- Fix 4: Add total_sessions if missing
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS total_sessions INTEGER DEFAULT 0;

-- Fix 5: Add price_paid if missing
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS price_paid DECIMAL(10,2);

-- Fix 6: Add purchase_date if missing
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS purchase_date TIMESTAMPTZ DEFAULT NOW();

-- Fix 7: Add expiry_date if missing
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- Fix 8: Set expiry_date for records without it (30 days from purchase)
UPDATE client_packages
SET expiry_date = COALESCE(purchase_date, NOW()) + INTERVAL '30 days'
WHERE expiry_date IS NULL;

-- Fix 9: Delete orphaned client_packages (where package doesn't exist)
DELETE FROM client_packages
WHERE package_id NOT IN (SELECT id FROM packages);

\echo '';
\echo '========================================';
\echo '  STEP 5: Checking Khun bie specifically';
\echo '========================================';

-- Find Khun bie
SELECT
  id,
  full_name,
  email,
  role,
  '✅ Found Khun bie' as status
FROM users
WHERE full_name ILIKE '%bie%'
   OR email ILIKE '%bie%'
ORDER BY created_at DESC;

-- Check Khun bie's packages
SELECT
  cp.id as client_package_id,
  cp.client_id,
  cp.package_id,
  cp.status,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.price_paid,
  cp.purchase_date,
  cp.expiry_date,
  u.full_name as client_name
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.full_name ILIKE '%bie%'
   OR u.email ILIKE '%bie%'
ORDER BY cp.created_at DESC;

\echo '';
\echo '========================================';
\echo '  STEP 6: Check available packages';
\echo '========================================';

-- Show all available packages
SELECT
  id,
  name,
  session_count,
  price,
  validity_days,
  is_active,
  CASE
    WHEN price = 1800 THEN '✅ 1800 BAHT PACKAGE'
    ELSE 'Other package'
  END as package_type
FROM packages
WHERE is_active = true
ORDER BY price;

\echo '';
\echo '========================================';
\echo '  STEP 7: Final verification';
\echo '========================================';

-- Count packages by status
SELECT
  COALESCE(status, 'NULL') as status,
  COUNT(*) as count
FROM client_packages
GROUP BY status;

-- Show clients who can book
SELECT
  u.full_name as client,
  cp.status,
  cp.remaining_sessions,
  cp.expiry_date,
  CASE
    WHEN cp.remaining_sessions > 0 AND cp.status = 'active' AND cp.expiry_date > NOW()
      THEN '✅ CAN BOOK SESSIONS'
    WHEN cp.status != 'active' THEN '❌ STATUS: ' || cp.status
    WHEN cp.remaining_sessions <= 0 THEN '❌ NO SESSIONS LEFT'
    WHEN cp.expiry_date <= NOW() THEN '❌ EXPIRED'
    ELSE '❌ CANNOT BOOK (UNKNOWN REASON)'
  END as booking_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.role = 'client'
ORDER BY cp.purchase_date DESC;

\echo '';
\echo '========================================';
\echo '  ✅ DIAGNOSIS AND FIX COMPLETE';
\echo '========================================';
