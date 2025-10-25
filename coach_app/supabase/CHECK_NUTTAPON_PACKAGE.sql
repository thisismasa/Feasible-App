-- ============================================================================
-- CHECK AND FIX NUTTAPON'S PACKAGE
-- ============================================================================
-- Email: nattapon@gmail.com
-- Phone: 0987654321
-- Expected: 10 sessions package, paid 17,000 THB
-- ============================================================================

-- STEP 1: Find the client
SELECT
  '🔍 FIND CLIENT' as step,
  id,
  full_name,
  email,
  phone,
  role
FROM users
WHERE email LIKE '%nattapon%'
   OR phone LIKE '%0987654321%'
   OR full_name LIKE '%Nuttapon%';

-- STEP 2: Check client's packages
SELECT
  '📦 CLIENT PACKAGES' as step,
  cp.id,
  cp.client_id,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.price_paid,
  cp.purchase_date,
  cp.expiry_date,
  cp.created_at,
  CASE
    WHEN cp.status IS NULL THEN '❌ Status is NULL'
    WHEN cp.status != 'active' THEN '❌ Status is: ' || cp.status
    WHEN cp.payment_status IS NULL THEN '❌ Payment status is NULL'
    WHEN cp.payment_status != 'paid' THEN '❌ Payment status is: ' || cp.payment_status
    WHEN cp.sessions_remaining IS NULL THEN '❌ sessions_remaining is NULL'
    WHEN cp.sessions_remaining <= 0 THEN '❌ sessions_remaining is: ' || cp.sessions_remaining::text
    WHEN cp.expiry_date < NOW() THEN '❌ Expired on: ' || cp.expiry_date::text
    ELSE '✅ Should be active'
  END as issue
FROM client_packages cp
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE email LIKE '%nattapon%'
     OR phone LIKE '%0987654321%'
     OR full_name LIKE '%Nuttapon%'
)
ORDER BY cp.created_at DESC;

-- STEP 3: Check payment transactions for this client
SELECT
  '💰 PAYMENT TRANSACTIONS' as step,
  pt.id,
  pt.client_id,
  pt.amount,
  pt.payment_method,
  pt.transaction_type,
  pt.created_at,
  pt.package_id
FROM payment_transactions pt
WHERE pt.client_id IN (
  SELECT id FROM users
  WHERE email LIKE '%nattapon%'
     OR phone LIKE '%0987654321%'
     OR full_name LIKE '%Nuttapon%'
)
ORDER BY pt.created_at DESC;

-- STEP 4: Check if sessions_remaining column exists and is calculated
SELECT
  '🔧 CHECK sessions_remaining COLUMN' as step,
  column_name,
  data_type,
  is_nullable,
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
  AND column_name = 'sessions_remaining';

-- STEP 5: Fix the package if needed
-- First, let's manually calculate what sessions_remaining should be
WITH client_info AS (
  SELECT id FROM users
  WHERE email LIKE '%nattapon%'
     OR phone LIKE '%0987654321%'
     OR full_name LIKE '%Nuttapon%'
  LIMIT 1
)
UPDATE client_packages
SET
  status = 'active',
  payment_status = 'paid',
  sessions_used = COALESCE(sessions_used, 0),
  sessions_scheduled = COALESCE(sessions_scheduled, 0)
WHERE client_id IN (SELECT id FROM client_info)
  AND created_at > NOW() - INTERVAL '7 days';

-- STEP 6: Verify the fix
SELECT
  '✅ AFTER FIX' as step,
  u.full_name as client_name,
  u.email,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.price_paid,
  cp.expiry_date,
  CASE
    WHEN cp.status = 'active'
      AND cp.payment_status = 'paid'
      AND cp.sessions_remaining > 0
      AND cp.expiry_date > NOW()
    THEN '✅ READY FOR BOOKING'
    ELSE '❌ STILL HAS ISSUES'
  END as final_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.email LIKE '%nattapon%'
   OR u.phone LIKE '%0987654321%'
   OR u.full_name LIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- FINAL MESSAGE
-- ============================================================================
SELECT '🎉 Check complete! If status shows READY FOR BOOKING, refresh your Flutter app!' as message;
