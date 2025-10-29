-- ============================================================================
-- DIAGNOSE BOOKING ERROR - Fix "Unknown error"
-- ============================================================================
-- This script diagnoses and fixes the booking error for p'Poon client
-- ============================================================================

-- STEP 1: Check if RPC function exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname = 'book_session_with_validation'
  ) THEN
    RAISE NOTICE '✓ RPC function book_session_with_validation EXISTS';
  ELSE
    RAISE NOTICE '✗ RPC function book_session_with_validation MISSING!';
    RAISE NOTICE 'Need to deploy ENSURE_CONSISTENT_BOOKINGS.sql first';
  END IF;
END $$;

-- STEP 2: Check client exists
SELECT
  'Client Check' as check_type,
  CASE
    WHEN id IS NOT NULL THEN '✓ Client EXISTS'
    ELSE '✗ Client NOT FOUND'
  END as result,
  id,
  full_name,
  email,
  role
FROM users
WHERE id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41';

-- STEP 3: Check package exists and is valid
SELECT
  'Package Check' as check_type,
  CASE
    WHEN id IS NULL THEN '✗ Package NOT FOUND'
    WHEN status != 'active' THEN '✗ Package NOT ACTIVE (status: ' || status || ')'
    WHEN expiry_date <= NOW() THEN '✗ Package EXPIRED on ' || expiry_date::TEXT
    WHEN remaining_sessions <= 0 THEN '✗ NO SESSIONS REMAINING'
    ELSE '✓ Package is VALID'
  END as result,
  id,
  package_name,
  client_id,
  total_sessions,
  used_sessions,
  remaining_sessions,
  status,
  expiry_date,
  created_at
FROM client_packages
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';

-- STEP 4: Check if package belongs to client
SELECT
  'Package-Client Match' as check_type,
  CASE
    WHEN client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41' THEN '✓ Package belongs to client'
    ELSE '✗ Package does NOT belong to client (belongs to: ' || client_id || ')'
  END as result
FROM client_packages
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';

-- STEP 5: Test the booking with the RPC function directly
SELECT
  'Test Booking' as test_type,
  book_session_with_validation(
    p_client_id := 'ac6b34af-77e4-41c0-a0de-59ef190fab41'::UUID,
    p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID,
    p_scheduled_start := '2025-10-29 18:30:00+07'::TIMESTAMPTZ,
    p_duration_minutes := 60,
    p_package_id := 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'::UUID,
    p_session_type := 'in_person',
    p_location := NULL,
    p_notes := NULL
  ) as result;

-- If the above fails, it will show the exact error message


-- STEP 6: Check for existing conflicts at that time
SELECT
  'Conflict Check' as check_type,
  id,
  client_id,
  trainer_id,
  scheduled_start,
  scheduled_end,
  status,
  CASE
    WHEN trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
      THEN '✗ TRAINER has session at this time'
    WHEN client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
      THEN '✗ CLIENT has session at this time'
    ELSE 'Other session'
  END as conflict_type
FROM sessions
WHERE (
  trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  OR client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
)
AND status IN ('scheduled', 'confirmed')
AND (
  ('2025-10-29 18:30:00+07'::TIMESTAMPTZ, '2025-10-29 19:30:00+07'::TIMESTAMPTZ)
  OVERLAPS
  (scheduled_start, scheduled_end)
);


-- STEP 7: Check sessions table structure
SELECT
  'Sessions Table' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'sessions'
  AND table_schema = 'public'
ORDER BY ordinal_position;


-- ============================================================================
-- COMMON FIXES
-- ============================================================================

-- FIX 1: If package has wrong remaining_sessions
UPDATE client_packages
SET
  remaining_sessions = total_sessions - used_sessions,
  updated_at = NOW()
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'
  AND remaining_sessions != (total_sessions - used_sessions);

-- FIX 2: If package is expired but shouldn't be
-- (Uncomment if needed)
-- UPDATE client_packages
-- SET expiry_date = NOW() + INTERVAL '30 days'
-- WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';

-- FIX 3: If package status is wrong
-- (Uncomment if needed)
-- UPDATE client_packages
-- SET status = 'active'
-- WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';


-- ============================================================================
-- FINAL VERIFICATION
-- ============================================================================

SELECT
  '========== FINAL CHECK ==========' as status,
  cp.package_name,
  cp.status as package_status,
  cp.remaining_sessions,
  cp.expiry_date,
  u.full_name as client_name,
  CASE
    WHEN cp.id IS NULL THEN '✗ Package not found'
    WHEN cp.status != 'active' THEN '✗ Package not active'
    WHEN cp.expiry_date <= NOW() THEN '✗ Package expired'
    WHEN cp.remaining_sessions <= 0 THEN '✗ No sessions remaining'
    WHEN cp.client_id != u.id THEN '✗ Package client mismatch'
    ELSE '✓ READY TO BOOK'
  END as ready_status
FROM client_packages cp
LEFT JOIN users u ON u.id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
WHERE cp.id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';
