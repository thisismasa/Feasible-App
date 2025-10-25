-- ============================================================================
-- COMPLETE DIAGNOSIS: Payment to Package Flow
-- ============================================================================
-- This checks EVERY step from payment to showing active package
-- ============================================================================

-- STEP 1: Find ALL clients named Nuttapon or similar
SELECT
  '👥 ALL MATCHING CLIENTS' as info,
  id,
  full_name,
  email,
  phone,
  role,
  created_at
FROM users
WHERE full_name ILIKE '%nutt%'
   OR email ILIKE '%natt%'
   OR phone LIKE '%0987654321%'
ORDER BY created_at DESC;

-- STEP 2: Check ALL packages for these clients
SELECT
  '📦 ALL PACKAGES FOR THESE CLIENTS' as info,
  cp.*
FROM client_packages cp
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE full_name ILIKE '%nutt%'
     OR email ILIKE '%natt%'
     OR phone LIKE '%0987654321%'
)
ORDER BY cp.created_at DESC;

-- STEP 3: Check ALL payment transactions
SELECT
  '💰 ALL PAYMENT TRANSACTIONS' as info,
  pt.*
FROM payment_transactions pt
WHERE pt.client_id IN (
  SELECT id FROM users
  WHERE full_name ILIKE '%nutt%'
     OR email ILIKE '%natt%'
     OR phone LIKE '%0987654321%'
)
ORDER BY pt.created_at DESC;

-- STEP 4: Check table structure
SELECT
  '🔧 CLIENT_PACKAGES STRUCTURE' as info,
  column_name,
  data_type,
  is_nullable,
  column_default,
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
ORDER BY ordinal_position;

-- STEP 5: Check if there are ANY active packages at all
SELECT
  '📊 ALL ACTIVE PACKAGES IN SYSTEM' as info,
  COUNT(*) as total_active_packages
FROM client_packages
WHERE status = 'active';

-- STEP 6: Check what the Flutter app is querying
-- This mimics the exact query from real_supabase_service.dart line 714
SELECT
  '🔍 WHAT FLUTTER QUERIES (mimicking code)' as info,
  cp.*,
  p.name as package_details_name,
  p.sessions as package_details_sessions
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE full_name ILIKE '%nutt%'
     OR email ILIKE '%natt%'
)
  AND cp.status = 'active'
ORDER BY cp.created_at DESC;

-- STEP 7: Check if sessions_remaining exists and has values
SELECT
  '🎯 SESSIONS_REMAINING CHECK' as info,
  id,
  package_name,
  total_sessions,
  sessions_used,
  sessions_scheduled,
  sessions_remaining,
  (total_sessions - COALESCE(sessions_used, 0) - COALESCE(sessions_scheduled, 0)) as manually_calculated,
  CASE
    WHEN sessions_remaining IS NULL THEN '❌ NULL'
    WHEN sessions_remaining = (total_sessions - COALESCE(sessions_used, 0) - COALESCE(sessions_scheduled, 0))
      THEN '✅ Correct'
    ELSE '⚠️ Mismatch'
  END as status
FROM client_packages
WHERE client_id IN (
  SELECT id FROM users
  WHERE full_name ILIKE '%nutt%'
     OR email ILIKE '%natt%'
);

-- STEP 8: Find the EXACT issue
SELECT
  '🔍 EXACT ISSUE DIAGNOSIS' as info,
  u.full_name,
  u.email,
  cp.id as package_id,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.total_sessions,
  cp.sessions_remaining,
  cp.expiry_date,
  CASE
    WHEN cp.id IS NULL THEN '❌ NO PACKAGE EXISTS IN DATABASE'
    WHEN cp.status IS NULL THEN '❌ status column is NULL'
    WHEN cp.status != 'active' THEN '❌ status = ' || cp.status || ' (not active)'
    WHEN cp.payment_status IS NULL THEN '❌ payment_status is NULL'
    WHEN cp.payment_status != 'paid' THEN '❌ payment_status = ' || cp.payment_status
    WHEN cp.sessions_remaining IS NULL THEN '❌ sessions_remaining is NULL'
    WHEN cp.sessions_remaining <= 0 THEN '❌ sessions_remaining = ' || cp.sessions_remaining::text
    WHEN cp.expiry_date < NOW() THEN '❌ EXPIRED on ' || cp.expiry_date::text
    ELSE '✅ SHOULD BE VISIBLE'
  END as issue,
  cp.created_at
FROM users u
LEFT JOIN client_packages cp ON u.id = cp.client_id
WHERE u.full_name ILIKE '%nutt%'
   OR u.email ILIKE '%natt%'
   OR u.phone LIKE '%0987654321%'
ORDER BY cp.created_at DESC NULLS LAST;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT '🎯 DIAGNOSIS COMPLETE - Check results above' as message;
