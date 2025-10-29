-- ============================================================================
-- CHECK KHUN BIE'S PACKAGE STATUS
-- ============================================================================
-- Diagnose why Khun bie shows "no active package" after payment
-- ============================================================================

-- STEP 1: Find Khun bie in users table
-- ============================================================================
SELECT
  '🔍 STEP 1: Finding Khun bie in database' as step;

SELECT
  id,
  full_name,
  email,
  role,
  created_at,
  '✅ Found Khun bie' as status
FROM users
WHERE full_name ILIKE '%bie%'
   OR email ILIKE '%bie%'
ORDER BY created_at DESC;

-- STEP 2: Check if Khun bie has any packages assigned
-- ============================================================================
SELECT
  '🔍 STEP 2: Checking Khun bie packages' as step;

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
  u.full_name as client_name,
  CASE
    WHEN cp.status IS NULL THEN '❌ STATUS IS NULL!'
    WHEN cp.status != 'active' THEN '⚠️ STATUS NOT ACTIVE: ' || cp.status
    WHEN cp.package_id NOT IN (SELECT id FROM packages) THEN '❌ PACKAGE DOES NOT EXIST!'
    WHEN cp.remaining_sessions <= 0 THEN '⚠️ NO SESSIONS REMAINING'
    WHEN cp.expiry_date < NOW() THEN '⚠️ PACKAGE EXPIRED'
    ELSE '✅ PACKAGE LOOKS GOOD'
  END as diagnosis
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.full_name ILIKE '%bie%'
   OR u.email ILIKE '%bie%'
ORDER BY cp.created_at DESC;

-- STEP 3: Check packages table for 1800 baht package
-- ============================================================================
SELECT
  '🔍 STEP 3: Finding 1800 baht package' as step;

SELECT
  id,
  name,
  session_count,
  price,
  validity_days,
  is_active,
  CASE
    WHEN is_active = false THEN '❌ PACKAGE INACTIVE!'
    WHEN price = 1800 THEN '✅ 1800 BAHT PACKAGE FOUND'
    ELSE '⚠️ DIFFERENT PRICE'
  END as status
FROM packages
WHERE price = 1800
   OR name ILIKE '%1800%'
   OR name ILIKE '%single%'
   OR session_count = 1
ORDER BY created_at DESC;

-- STEP 4: Check payment transactions for Khun bie
-- ============================================================================
SELECT
  '🔍 STEP 4: Checking payment transactions' as step;

SELECT
  pt.id as transaction_id,
  pt.client_id,
  pt.amount,
  pt.payment_method,
  pt.status as payment_status,
  pt.created_at as payment_date,
  u.full_name as client_name,
  '💰 Payment: ' || pt.amount || ' baht' as amount_info
FROM payment_transactions pt
JOIN users u ON pt.client_id = u.id
WHERE (u.full_name ILIKE '%bie%' OR u.email ILIKE '%bie%')
  AND pt.amount = 1800
ORDER BY pt.created_at DESC;

-- STEP 5: Fix Khun bie's package if needed
-- ============================================================================
SELECT
  '🔧 STEP 5: Attempting automatic fix' as step;

-- First, get Khun bie's user ID
DO $$
DECLARE
  v_client_id UUID;
  v_package_id UUID;
  v_client_package_id UUID;
  v_client_name TEXT;
BEGIN
  -- Find Khun bie
  SELECT id, full_name INTO v_client_id, v_client_name
  FROM users
  WHERE full_name ILIKE '%bie%'
     OR email ILIKE '%bie%'
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE NOTICE '❌ Could not find Khun bie in users table';
    RETURN;
  END IF;

  RAISE NOTICE '✅ Found client: % (ID: %)', v_client_name, v_client_id;

  -- Find 1800 baht package (1 session)
  SELECT id INTO v_package_id
  FROM packages
  WHERE price = 1800
    AND session_count = 1
    AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE NOTICE '❌ Could not find 1800 baht package. Creating it...';

    -- Create the package if it doesn't exist
    INSERT INTO packages (
      name,
      description,
      session_count,
      price,
      validity_days,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      'Single Session',
      '1 personal training session',
      1,
      1800,
      30,
      true,
      NOW(),
      NOW()
    ) RETURNING id INTO v_package_id;

    RAISE NOTICE '✅ Created package: % (ID: %)', 'Single Session', v_package_id;
  ELSE
    RAISE NOTICE '✅ Found package with price 1800 baht (ID: %)', v_package_id;
  END IF;

  -- Check if client already has this package
  SELECT id INTO v_client_package_id
  FROM client_packages
  WHERE client_id = v_client_id
    AND package_id = v_package_id;

  IF FOUND THEN
    -- Update existing package
    UPDATE client_packages
    SET status = 'active',
        total_sessions = 1,
        remaining_sessions = 1,
        sessions_scheduled = 0,
        price_paid = 1800,
        purchase_date = NOW(),
        expiry_date = NOW() + INTERVAL '30 days',
        updated_at = NOW()
    WHERE id = v_client_package_id;

    RAISE NOTICE '✅ Updated existing package assignment (ID: %)', v_client_package_id;
  ELSE
    -- Create new package assignment
    INSERT INTO client_packages (
      client_id,
      package_id,
      total_sessions,
      remaining_sessions,
      sessions_scheduled,
      price_paid,
      purchase_date,
      expiry_date,
      status,
      created_at,
      updated_at
    ) VALUES (
      v_client_id,
      v_package_id,
      1,
      1,
      0,
      1800,
      NOW(),
      NOW() + INTERVAL '30 days',
      'active',
      NOW(),
      NOW()
    ) RETURNING id INTO v_client_package_id;

    RAISE NOTICE '✅ Created new package assignment (ID: %)', v_client_package_id;
  END IF;

END $$;

-- STEP 6: Verify the fix worked
-- ============================================================================
SELECT
  '✅ STEP 6: Verification - Khun bie should now have active package' as step;

SELECT
  u.full_name as client,
  p.name as package_name,
  p.price as package_price,
  cp.status,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.price_paid,
  cp.purchase_date,
  cp.expiry_date,
  CASE
    WHEN cp.remaining_sessions > 0 AND cp.status = 'active' AND cp.expiry_date > NOW()
      THEN '✅ CAN BOOK SESSIONS!'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
JOIN packages p ON cp.package_id = p.id
WHERE u.full_name ILIKE '%bie%'
   OR u.email ILIKE '%bie%'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT
  '📊 SUMMARY: Khun bie Package Status' as summary;

SELECT
  (SELECT COUNT(*) FROM users WHERE full_name ILIKE '%bie%') as khun_bie_found,
  (SELECT COUNT(*) FROM client_packages cp JOIN users u ON cp.client_id = u.id
   WHERE (u.full_name ILIKE '%bie%' OR u.email ILIKE '%bie%') AND cp.status = 'active') as active_packages,
  (SELECT COUNT(*) FROM payment_transactions pt JOIN users u ON pt.client_id = u.id
   WHERE (u.full_name ILIKE '%bie%' OR u.email ILIKE '%bie%') AND pt.amount = 1800) as payments_1800_baht;
