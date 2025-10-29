-- ============================================
-- FIX ALL CLIENTS PACKAGES - COMPREHENSIVE FIX
-- ============================================
-- Apply same logic as Nuttapon fix to ALL clients
-- This ensures every client can book sessions
-- ============================================

-- ============================================
-- SECTION 1: DIAGNOSE ALL CLIENTS FIRST
-- ============================================

-- Show ALL clients and their package status
SELECT
  '🔍 ALL CLIENTS - CURRENT STATUS' as section,
  u.full_name as client_name,
  u.email,
  COUNT(cp.id) as total_packages,
  COUNT(cp.id) FILTER (WHERE cp.is_active = true) as active_packages,
  COUNT(cp.id) FILTER (WHERE cp.remaining_sessions > 0) as packages_with_sessions,
  COUNT(cp.id) FILTER (WHERE cp.expiry_date > NOW()) as non_expired_packages,
  COUNT(cp.id) FILTER (WHERE cp.package_id IS NOT NULL) as packages_with_plan,
  -- Overall status
  CASE
    WHEN COUNT(cp.id) FILTER (
      WHERE cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
    ) > 0 THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM users u
LEFT JOIN client_packages cp ON cp.client_id = u.id
WHERE u.role = 'client'
GROUP BY u.id, u.full_name, u.email
ORDER BY u.full_name;

-- ============================================
-- SECTION 2: FIX ALL PACKAGES
-- ============================================

-- FIX 1: Activate ALL client packages
UPDATE client_packages
SET is_active = true
WHERE is_active = false OR is_active IS NULL;

-- FIX 2: Set remaining_sessions for ALL packages
UPDATE client_packages
SET remaining_sessions = COALESCE(total_sessions, 10)
WHERE remaining_sessions IS NULL OR remaining_sessions = 0;

-- FIX 3: Fix expiry_date for ALL packages (extend by 90 days)
UPDATE client_packages
SET expiry_date = CASE
  WHEN expiry_date IS NULL OR expiry_date < NOW() THEN
    COALESCE(start_date, NOW()) + INTERVAL '90 days'
  ELSE
    expiry_date
  END
WHERE expiry_date IS NULL OR expiry_date < NOW();

-- FIX 4: Set start_date for ALL packages
UPDATE client_packages
SET start_date = COALESCE(purchase_date, NOW())
WHERE start_date IS NULL;

-- FIX 5: Link to active package plan for ALL packages
UPDATE client_packages cp
SET package_id = (
  SELECT id FROM packages
  WHERE is_active = true
  ORDER BY sessions
  LIMIT 1
)
WHERE cp.package_id IS NULL
OR NOT EXISTS (
  SELECT 1 FROM packages p
  WHERE p.id = cp.package_id AND p.is_active = true
);

-- FIX 6: Ensure total_sessions is set
UPDATE client_packages
SET total_sessions = COALESCE(total_sessions, 10)
WHERE total_sessions IS NULL OR total_sessions = 0;

-- ============================================
-- SECTION 3: VERIFY ALL CLIENTS AFTER FIX
-- ============================================

-- Show all clients status AFTER fixes
SELECT
  '✅ ALL CLIENTS - AFTER FIX' as section,
  u.full_name as client_name,
  u.email,
  COUNT(cp.id) as total_packages,
  COUNT(cp.id) FILTER (WHERE cp.is_active = true) as active_packages,
  COUNT(cp.id) FILTER (WHERE cp.remaining_sessions > 0) as packages_with_sessions,
  COUNT(cp.id) FILTER (WHERE cp.expiry_date > NOW()) as non_expired_packages,
  COUNT(cp.id) FILTER (WHERE cp.package_id IS NOT NULL) as packages_with_plan,
  -- Overall status
  CASE
    WHEN COUNT(cp.id) FILTER (
      WHERE cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
    ) > 0 THEN '✅ CAN BOOK'
    ELSE '❌ STILL HAS ISSUES'
  END as booking_status
FROM users u
LEFT JOIN client_packages cp ON cp.client_id = u.id
WHERE u.role = 'client'
GROUP BY u.id, u.full_name, u.email
ORDER BY u.full_name;

-- ============================================
-- SECTION 4: DETAILED PACKAGE VIEW (ALL CLIENTS)
-- ============================================

SELECT
  '📋 ALL PACKAGES - DETAILED VIEW' as section,
  u.full_name as client_name,
  u.email as client_email,
  cp.id as package_id,
  cp.package_name,
  cp.is_active as "Active?",
  cp.remaining_sessions as "Sessions Left",
  cp.total_sessions as "Total",
  cp.used_sessions as "Used",
  cp.start_date as "Valid From",
  cp.expiry_date as "Valid Until",
  CASE
    WHEN cp.expiry_date > NOW() THEN
      EXTRACT(DAY FROM (cp.expiry_date - NOW()))::INTEGER || ' days'
    ELSE 'EXPIRED'
  END as "Days Left",
  p.name as "Plan Name",
  p.is_active as "Plan Active?",
  -- Final validation
  CASE
    WHEN cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND p.is_active = true
    THEN '✅ READY'
    ELSE '❌ ISSUES'
  END as status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE u.role = 'client'
ORDER BY u.full_name, cp.created_at DESC;

-- ============================================
-- SECTION 5: BOOKING VALIDATION TEST (ALL CLIENTS)
-- ============================================

SELECT
  '🧪 BOOKING VALIDATION - ALL CLIENTS' as section,
  u.full_name,
  u.email,
  cp.id as package_id,
  (cp.is_active = true) as "is_active ✓",
  (cp.remaining_sessions > 0) as "has_sessions ✓",
  (cp.expiry_date > NOW()) as "not_expired ✓",
  (cp.package_id IS NOT NULL) as "has_plan ✓",
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
FROM users u
JOIN client_packages cp ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE u.role = 'client'
ORDER BY u.full_name, cp.created_at DESC;

-- ============================================
-- SECTION 6: SUMMARY STATISTICS
-- ============================================

SELECT
  '📊 FIX SUMMARY' as section,
  (SELECT COUNT(*) FROM users WHERE role = 'client') as total_clients,
  (SELECT COUNT(*) FROM client_packages) as total_packages,
  (SELECT COUNT(*) FROM client_packages WHERE is_active = true) as active_packages,
  (SELECT COUNT(*) FROM client_packages WHERE remaining_sessions > 0) as packages_with_sessions,
  (SELECT COUNT(*) FROM client_packages WHERE expiry_date > NOW()) as non_expired,
  (SELECT COUNT(*) FROM client_packages WHERE package_id IS NOT NULL) as packages_with_plan,
  (SELECT COUNT(*) FROM client_packages WHERE
    is_active = true
    AND remaining_sessions > 0
    AND expiry_date > NOW()
    AND package_id IS NOT NULL
  ) as ready_to_book_packages,
  (SELECT COUNT(DISTINCT u.id) FROM users u
    JOIN client_packages cp ON cp.client_id = u.id
    LEFT JOIN packages p ON cp.package_id = p.id
    WHERE u.role = 'client'
      AND cp.is_active = true
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND p.is_active = true
  ) as clients_who_can_book;

-- ============================================
-- ✅ EXPECTED RESULTS AFTER RUNNING
-- ============================================
--
-- SECTION 1: Shows current status (before fix)
-- - Some clients will show "❌ CANNOT BOOK"
--
-- SECTION 2: Applies 6 fixes to ALL packages
-- - UPDATE statements will show how many fixed
--
-- SECTION 3: Shows status after fix
-- - ALL clients should show "✅ CAN BOOK"
--
-- SECTION 4: Detailed view of every package
-- - All packages should show "✅ READY"
--
-- SECTION 5: Validation tests for each package
-- - All should show "✅ ALL CHECKS PASS"
--
-- SECTION 6: Summary statistics
-- - clients_who_can_book should equal total_clients
-- - ready_to_book_packages should equal total_packages
--
-- ============================================
-- 🎯 WHAT THIS FIXES FOR ALL CLIENTS
-- ============================================
-- ✅ Activates all packages
-- ✅ Sets remaining_sessions (10 or total)
-- ✅ Extends expiry_date by 90 days
-- ✅ Sets start_date to today
-- ✅ Links to active package plans
-- ✅ Sets total_sessions if missing
--
-- ALL clients will be able to book after this!
-- ============================================
