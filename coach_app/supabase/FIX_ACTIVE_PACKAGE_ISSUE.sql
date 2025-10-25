-- ============================================================================
-- FIX: "No active package" Issue After Payment
-- ============================================================================
-- This script diagnoses and fixes the issue where clients show
-- "No active package" even after successfully paying for one
-- ============================================================================

-- STEP 1: Check current client_packages structure
SELECT
  '📋 CLIENT_PACKAGES TABLE STRUCTURE' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
ORDER BY ordinal_position;

-- STEP 2: Check if there are any packages in the database
SELECT
  '📊 CURRENT PACKAGES IN DATABASE' as info,
  COUNT(*) as total_packages,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_packages,
  COUNT(CASE WHEN status != 'active' THEN 1 END) as inactive_packages
FROM client_packages;

-- STEP 3: Show recent packages with their status
SELECT
  '🔍 RECENT PACKAGES DETAIL' as info,
  cp.id,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  CASE
    WHEN cp.sessions_remaining IS NULL THEN '❌ NULL remaining_sessions'
    WHEN cp.sessions_remaining > 0 THEN '✅ Has remaining sessions'
    ELSE '⚠️ Zero remaining sessions'
  END as remaining_status,
  cp.purchase_date,
  cp.expiry_date
FROM client_packages cp
ORDER BY cp.created_at DESC
LIMIT 5;

-- STEP 4: Check if sessions_remaining column exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'client_packages'
      AND column_name = 'sessions_remaining'
  ) THEN
    RAISE NOTICE '⚠️ sessions_remaining column does not exist!';
    RAISE NOTICE 'Creating sessions_remaining as a generated column...';

    -- Add sessions_remaining as a GENERATED column
    ALTER TABLE client_packages
    ADD COLUMN sessions_remaining INTEGER
    GENERATED ALWAYS AS (total_sessions - sessions_used - sessions_scheduled) STORED;

    RAISE NOTICE '✅ sessions_remaining column created';
  ELSE
    RAISE NOTICE '✅ sessions_remaining column already exists';
  END IF;
END $$;

-- STEP 5: Verify sessions_remaining is working
SELECT
  '✅ VERIFICATION: sessions_remaining calculation' as info,
  id,
  package_name,
  total_sessions,
  sessions_used,
  sessions_scheduled,
  sessions_remaining,
  (total_sessions - sessions_used - sessions_scheduled) as calculated_remaining,
  CASE
    WHEN sessions_remaining = (total_sessions - sessions_used - sessions_scheduled) THEN '✅ Correct'
    ELSE '❌ Mismatch'
  END as verification
FROM client_packages
ORDER BY created_at DESC
LIMIT 5;

-- STEP 6: Find packages that should be active but might not be showing
SELECT
  '🔍 PACKAGES THAT SHOULD BE AVAILABLE FOR BOOKING' as info,
  cp.id,
  u.full_name as client_name,
  u.email as client_email,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.sessions_remaining,
  cp.expiry_date,
  CASE
    WHEN cp.status != 'active' THEN '❌ Status not active'
    WHEN cp.payment_status != 'paid' THEN '❌ Payment not marked as paid'
    WHEN cp.sessions_remaining <= 0 THEN '❌ No sessions remaining'
    WHEN cp.expiry_date < NOW() THEN '❌ Package expired'
    ELSE '✅ Should be available'
  END as availability_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.created_at > NOW() - INTERVAL '7 days'  -- Recent purchases
ORDER BY cp.created_at DESC;

-- STEP 7: Fix any packages with wrong status
UPDATE client_packages
SET status = 'active'
WHERE payment_status = 'paid'
  AND sessions_remaining > 0
  AND expiry_date > NOW()
  AND status != 'active';

-- Show what was fixed
SELECT
  '✅ FIXED PACKAGES' as info,
  COUNT(*) as packages_fixed
FROM client_packages
WHERE payment_status = 'paid'
  AND sessions_remaining > 0
  AND expiry_date > NOW()
  AND status = 'active';

-- STEP 8: Final verification query
SELECT
  '🎉 FINAL STATUS: Active packages ready for booking' as info,
  u.full_name as client_name,
  u.email,
  cp.package_name,
  cp.status,
  cp.payment_status,
  cp.sessions_remaining,
  cp.purchase_date,
  cp.expiry_date
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.status = 'active'
  AND cp.payment_status = 'paid'
  AND cp.sessions_remaining > 0
  AND cp.expiry_date > NOW()
ORDER BY cp.created_at DESC;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT '✅ Diagnosis and fix complete!' as message;
SELECT 'Refresh your Flutter app to see active packages' as next_step;
