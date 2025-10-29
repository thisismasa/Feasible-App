-- ============================================================================
-- FINAL VERIFICATION TEST - CONFIRM ZERO ERRORS
-- ============================================================================
-- This will verify that ALL fixes are applied and booking works
-- ============================================================================

-- ============================================================================
-- TEST 1: VERIFY SCHEMA HAS 'STATUS' COLUMN
-- ============================================================================

SELECT
  '✅ TEST 1: SCHEMA VERIFICATION' as test_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'client_packages'
        AND column_name = 'status'
        AND data_type = 'text'
    ) THEN '✅ PASS - status column exists'
    ELSE '❌ FAIL - status column missing'
  END as result;

-- Show all columns
SELECT
  '📋 CURRENT SCHEMA' as section,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'client_packages'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================================================
-- TEST 2: VERIFY ALL PACKAGES HAVE STATUS = 'active'
-- ============================================================================

SELECT
  '✅ TEST 2: STATUS COLUMN DATA' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE status = 'active') as status_active,
  COUNT(*) FILTER (WHERE status IS NULL) as status_null,
  COUNT(*) FILTER (WHERE status NOT IN ('active', 'expired', 'completed', 'frozen', 'cancelled')) as status_invalid,
  CASE
    WHEN COUNT(*) FILTER (WHERE status IS NULL OR status NOT IN ('active', 'expired', 'completed', 'frozen', 'cancelled')) = 0
    THEN '✅ PASS - All packages have valid status'
    ELSE '❌ FAIL - Some packages have invalid status'
  END as result
FROM client_packages;

-- ============================================================================
-- TEST 3: VERIFY ALL PACKAGES HAVE REMAINING SESSIONS
-- ============================================================================

SELECT
  '✅ TEST 3: REMAINING SESSIONS' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE remaining_sessions > 0) as has_sessions,
  COUNT(*) FILTER (WHERE remaining_sessions IS NULL) as null_sessions,
  COUNT(*) FILTER (WHERE remaining_sessions = 0) as zero_sessions,
  CASE
    WHEN COUNT(*) FILTER (WHERE remaining_sessions IS NULL OR remaining_sessions = 0) = 0
    THEN '✅ PASS - All packages have sessions'
    ELSE '❌ FAIL - Some packages missing sessions'
  END as result
FROM client_packages;

-- ============================================================================
-- TEST 4: VERIFY ALL PACKAGES NOT EXPIRED
-- ============================================================================

SELECT
  '✅ TEST 4: EXPIRY DATES' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE expiry_date > NOW()) as not_expired,
  COUNT(*) FILTER (WHERE expiry_date IS NULL) as null_expiry,
  COUNT(*) FILTER (WHERE expiry_date <= NOW()) as expired,
  CASE
    WHEN COUNT(*) FILTER (WHERE expiry_date IS NULL OR expiry_date <= NOW()) = 0
    THEN '✅ PASS - All packages not expired'
    ELSE '❌ FAIL - Some packages expired'
  END as result
FROM client_packages;

-- ============================================================================
-- TEST 5: VERIFY ALL PACKAGES LINKED TO ACTIVE PLANS
-- ============================================================================

SELECT
  '✅ TEST 5: PACKAGE PLANS' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE cp.package_id IS NOT NULL) as has_plan,
  COUNT(*) FILTER (WHERE p.is_active = true) as plan_active,
  COUNT(*) FILTER (WHERE cp.package_id IS NULL) as no_plan,
  COUNT(*) FILTER (WHERE p.is_active = false OR p.id IS NULL) as plan_inactive,
  CASE
    WHEN COUNT(*) FILTER (WHERE cp.package_id IS NULL OR p.is_active = false OR p.id IS NULL) = 0
    THEN '✅ PASS - All packages have active plans'
    ELSE '❌ FAIL - Some packages missing active plans'
  END as result
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id;

-- ============================================================================
-- TEST 6: VERIFY ALL PACKAGES HAVE PAYMENT STATUS
-- ============================================================================

SELECT
  '✅ TEST 6: PAYMENT STATUS' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE payment_status IN ('paid', 'completed')) as paid,
  COUNT(*) FILTER (WHERE payment_status IS NULL) as null_payment,
  COUNT(*) FILTER (WHERE payment_status NOT IN ('paid', 'completed', 'pending', 'failed', 'refunded')) as invalid_payment,
  CASE
    WHEN COUNT(*) FILTER (WHERE payment_status IS NULL OR payment_status NOT IN ('paid', 'completed', 'pending', 'failed', 'refunded')) = 0
    THEN '✅ PASS - All packages have valid payment status'
    ELSE '❌ FAIL - Some packages have invalid payment status'
  END as result
FROM client_packages;

-- ============================================================================
-- TEST 7: COMPREHENSIVE BOOKING VALIDATION - ALL CONDITIONS
-- ============================================================================

SELECT
  '✅ TEST 7: COMPLETE BOOKING VALIDATION' as test_name,
  COUNT(*) as total_packages,
  COUNT(*) FILTER (WHERE
    cp.status = 'active'
    AND cp.is_active = true
    AND cp.remaining_sessions > 0
    AND cp.expiry_date > NOW()
    AND cp.package_id IS NOT NULL
    AND p.is_active = true
    AND cp.payment_status IN ('paid', 'completed')
  ) as ready_to_book,
  COUNT(*) - COUNT(*) FILTER (WHERE
    cp.status = 'active'
    AND cp.is_active = true
    AND cp.remaining_sessions > 0
    AND cp.expiry_date > NOW()
    AND cp.package_id IS NOT NULL
    AND p.is_active = true
    AND cp.payment_status IN ('paid', 'completed')
  ) as not_ready,
  CASE
    WHEN COUNT(*) = COUNT(*) FILTER (WHERE
      cp.status = 'active'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
      AND p.is_active = true
      AND cp.payment_status IN ('paid', 'completed')
    ) THEN '✅ PASS - All packages ready to book'
    ELSE '⚠️ WARNING - Some packages not ready'
  END as result
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id;

-- ============================================================================
-- TEST 8: CLIENT-LEVEL VALIDATION - EACH CLIENT CAN BOOK
-- ============================================================================

SELECT
  '✅ TEST 8: CLIENT BOOKING STATUS' as test_name,
  COUNT(DISTINCT u.id) as total_clients,
  COUNT(DISTINCT CASE WHEN
    cp.status = 'active'
    AND cp.is_active = true
    AND cp.remaining_sessions > 0
    AND cp.expiry_date > NOW()
    AND p.is_active = true
    AND cp.payment_status IN ('paid', 'completed')
  THEN u.id END) as clients_can_book,
  COUNT(DISTINCT u.id) - COUNT(DISTINCT CASE WHEN
    cp.status = 'active'
    AND cp.is_active = true
    AND cp.remaining_sessions > 0
    AND cp.expiry_date > NOW()
    AND p.is_active = true
    AND cp.payment_status IN ('paid', 'completed')
  THEN u.id END) as clients_cannot_book,
  CASE
    WHEN COUNT(DISTINCT u.id) = COUNT(DISTINCT CASE WHEN
      cp.status = 'active'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND p.is_active = true
      AND cp.payment_status IN ('paid', 'completed')
    THEN u.id END)
    THEN '✅ PASS - All clients can book'
    ELSE '⚠️ WARNING - Some clients cannot book'
  END as result
FROM users u
LEFT JOIN client_packages cp ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE u.role = 'client';

-- ============================================================================
-- TEST 9: NUTTAPON SPECIFIC TEST
-- ============================================================================

SELECT
  '✅ TEST 9: NUTTAPON BOOKING STATUS' as test_name,
  u.full_name as client_name,
  u.email,
  cp.id as package_id,
  cp.package_name,
  (cp.status = 'active') as "status_active ✓",
  (cp.is_active = true) as "is_active ✓",
  (cp.remaining_sessions > 0) as "has_sessions ✓",
  (cp.expiry_date > NOW()) as "not_expired ✓",
  (cp.package_id IS NOT NULL) as "has_plan ✓",
  (p.is_active = true) as "plan_active ✓",
  (cp.payment_status IN ('paid', 'completed')) as "paid ✓",
  CASE
    WHEN cp.status = 'active'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
      AND p.is_active = true
      AND cp.payment_status IN ('paid', 'completed')
    THEN '✅ PASS - Nuttapon can book'
    ELSE '❌ FAIL - Nuttapon cannot book'
  END as result
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%';

-- ============================================================================
-- TEST 10: DETAILED CLIENT VIEW - ALL CLIENTS
-- ============================================================================

SELECT
  '✅ TEST 10: ALL CLIENTS DETAILED STATUS' as test_name,
  u.full_name as client_name,
  u.email,
  cp.package_name,
  cp.status as "Status",
  cp.remaining_sessions as "Sessions",
  CASE
    WHEN cp.expiry_date > NOW() THEN
      EXTRACT(DAY FROM (cp.expiry_date - NOW()))::INTEGER || ' days left'
    ELSE 'EXPIRED'
  END as "Expires",
  p.name as "Plan",
  cp.payment_status as "Payment",
  CASE
    WHEN cp.status = 'active'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND p.is_active = true
      AND cp.payment_status IN ('paid', 'completed')
    THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM users u
JOIN client_packages cp ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE u.role = 'client'
ORDER BY u.full_name;

-- ============================================================================
-- FINAL SUMMARY - ZERO ERRORS REPORT
-- ============================================================================

WITH test_results AS (
  -- Schema test
  SELECT 1 as test_num,
    CASE WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'client_packages' AND column_name = 'status'
    ) THEN 1 ELSE 0 END as passed

  UNION ALL

  -- Status data test
  SELECT 2,
    CASE WHEN (SELECT COUNT(*) FROM client_packages WHERE status IS NULL) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Remaining sessions test
  SELECT 3,
    CASE WHEN (SELECT COUNT(*) FROM client_packages WHERE remaining_sessions IS NULL OR remaining_sessions = 0) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Expiry date test
  SELECT 4,
    CASE WHEN (SELECT COUNT(*) FROM client_packages WHERE expiry_date IS NULL OR expiry_date <= NOW()) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Package plan test
  SELECT 5,
    CASE WHEN (SELECT COUNT(*) FROM client_packages cp LEFT JOIN packages p ON cp.package_id = p.id WHERE cp.package_id IS NULL OR p.is_active = false) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Payment status test
  SELECT 6,
    CASE WHEN (SELECT COUNT(*) FROM client_packages WHERE payment_status IS NULL) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Complete booking validation test
  SELECT 7,
    CASE WHEN (
      SELECT COUNT(*) FROM client_packages cp
      LEFT JOIN packages p ON cp.package_id = p.id
      WHERE NOT (
        cp.status = 'active'
        AND cp.is_active = true
        AND cp.remaining_sessions > 0
        AND cp.expiry_date > NOW()
        AND cp.package_id IS NOT NULL
        AND p.is_active = true
        AND cp.payment_status IN ('paid', 'completed')
      )
    ) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Client-level test
  SELECT 8,
    CASE WHEN (
      SELECT COUNT(DISTINCT u.id) FROM users u
      LEFT JOIN client_packages cp ON cp.client_id = u.id
      LEFT JOIN packages p ON cp.package_id = p.id
      WHERE u.role = 'client'
        AND NOT (
          cp.status = 'active'
          AND cp.is_active = true
          AND cp.remaining_sessions > 0
          AND cp.expiry_date > NOW()
          AND p.is_active = true
          AND cp.payment_status IN ('paid', 'completed')
        )
    ) = 0 THEN 1 ELSE 0 END

  UNION ALL

  -- Nuttapon specific test
  SELECT 9,
    CASE WHEN EXISTS (
      SELECT 1 FROM client_packages cp
      JOIN users u ON cp.client_id = u.id
      LEFT JOIN packages p ON cp.package_id = p.id
      WHERE (LOWER(u.full_name) LIKE '%nuttapon%' OR LOWER(u.email) LIKE '%nuttapon%')
        AND cp.status = 'active'
        AND cp.is_active = true
        AND cp.remaining_sessions > 0
        AND cp.expiry_date > NOW()
        AND p.is_active = true
        AND cp.payment_status IN ('paid', 'completed')
    ) THEN 1 ELSE 0 END

  UNION ALL

  -- All clients can book test
  SELECT 10,
    CASE WHEN (
      SELECT COUNT(*) FROM users u
      JOIN client_packages cp ON cp.client_id = u.id
      LEFT JOIN packages p ON cp.package_id = p.id
      WHERE u.role = 'client'
        AND NOT (
          cp.status = 'active'
          AND cp.is_active = true
          AND cp.remaining_sessions > 0
          AND cp.expiry_date > NOW()
          AND p.is_active = true
          AND cp.payment_status IN ('paid', 'completed')
        )
    ) = 0 THEN 1 ELSE 0 END
)
SELECT
  '🎯 FINAL SUMMARY - ZERO ERRORS REPORT' as section,
  COUNT(*) as total_tests,
  SUM(passed) as tests_passed,
  COUNT(*) - SUM(passed) as tests_failed,
  ROUND((SUM(passed)::DECIMAL / COUNT(*)) * 100, 2) || '%' as success_rate,
  CASE
    WHEN SUM(passed) = COUNT(*) THEN '✅ ALL TESTS PASSED - ZERO ERRORS'
    ELSE '❌ SOME TESTS FAILED - ERRORS FOUND'
  END as final_result
FROM test_results;

-- ============================================================================
-- DETAILED BREAKDOWN BY CLIENT
-- ============================================================================

SELECT
  '📊 CLIENT BREAKDOWN' as section,
  u.full_name as client_name,
  u.email,
  COUNT(cp.id) as total_packages,
  COUNT(cp.id) FILTER (WHERE cp.status = 'active') as active_packages,
  COUNT(cp.id) FILTER (WHERE cp.remaining_sessions > 0) as with_sessions,
  COUNT(cp.id) FILTER (WHERE cp.expiry_date > NOW()) as not_expired,
  COUNT(cp.id) FILTER (WHERE p.is_active = true) as active_plans,
  COUNT(cp.id) FILTER (WHERE cp.payment_status IN ('paid', 'completed')) as paid,
  COUNT(cp.id) FILTER (WHERE
    cp.status = 'active'
    AND cp.is_active = true
    AND cp.remaining_sessions > 0
    AND cp.expiry_date > NOW()
    AND p.is_active = true
    AND cp.payment_status IN ('paid', 'completed')
  ) as ready_packages,
  CASE
    WHEN COUNT(cp.id) FILTER (WHERE
      cp.status = 'active'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND p.is_active = true
      AND cp.payment_status IN ('paid', 'completed')
    ) > 0 THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as status
FROM users u
LEFT JOIN client_packages cp ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE u.role = 'client'
GROUP BY u.id, u.full_name, u.email
ORDER BY u.full_name;

-- ============================================================================
-- EXPECTED OUTPUT: ALL TESTS PASS
-- ============================================================================
--
-- TEST 1: ✅ PASS - status column exists
-- TEST 2: ✅ PASS - All packages have valid status
-- TEST 3: ✅ PASS - All packages have sessions
-- TEST 4: ✅ PASS - All packages not expired
-- TEST 5: ✅ PASS - All packages have active plans
-- TEST 6: ✅ PASS - All packages have valid payment status
-- TEST 7: ✅ PASS - All packages ready to book
-- TEST 8: ✅ PASS - All clients can book
-- TEST 9: ✅ PASS - Nuttapon can book
-- TEST 10: Shows all clients with "✅ CAN BOOK"
--
-- FINAL SUMMARY:
-- total_tests: 10
-- tests_passed: 10
-- tests_failed: 0
-- success_rate: 100.00%
-- final_result: ✅ ALL TESTS PASSED - ZERO ERRORS
--
-- ============================================================================
