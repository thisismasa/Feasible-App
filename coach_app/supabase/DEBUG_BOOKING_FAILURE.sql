-- ============================================================================
-- DEBUG: Why booking failed with "No remaining sessions in package"
-- ============================================================================

-- ============================================================================
-- PART 1: Check the package that was being used
-- ============================================================================

SELECT '=== PACKAGE STATE RIGHT NOW ===' as section;

SELECT
  cp.id as package_id,
  c.full_name as client_name,
  cp.package_name,
  cp.status,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked,
  CASE
    WHEN cp.remaining_sessions > 0 THEN '✅ Should allow booking'
    WHEN cp.remaining_sessions = 0 THEN '❌ Package full!'
    ELSE '⚠️ Negative sessions!'
  END as booking_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- PART 2: Check if another session was booked between sync and now
-- ============================================================================

SELECT '=== RECENT SESSIONS CREATED ===' as section;

SELECT
  s.id,
  s.created_at,
  s.scheduled_start,
  s.package_id,
  CASE
    WHEN s.package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce' THEN '⚠️ This is our package!'
    ELSE '✅ Different package'
  END as package_match,
  AGE(NOW(), s.created_at) as age
FROM sessions s
WHERE s.package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
ORDER BY s.created_at DESC
LIMIT 5;

-- ============================================================================
-- PART 3: Check all Nuttapon's packages
-- ============================================================================

SELECT '=== ALL NUTTAPON PACKAGES ===' as section;

SELECT
  cp.id,
  cp.package_name,
  cp.status,
  cp.remaining_sessions,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as session_count,
  CASE
    WHEN cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce' THEN '⚠️ Expected package'
    ELSE 'Other package'
  END as notes
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- PART 4: Test the booking function manually
-- ============================================================================

SELECT '=== TEST BOOKING FUNCTION ===' as section;

-- Get client ID
WITH client_info AS (
  SELECT id FROM users WHERE full_name ILIKE '%Nuttapon%' LIMIT 1
),
trainer_info AS (
  SELECT id FROM users WHERE role = 'trainer' LIMIT 1
)
SELECT
  book_session_with_validation(
    (SELECT id FROM client_info),
    (SELECT id FROM trainer_info),
    '2025-12-15 10:00:00+00'::TIMESTAMPTZ,
    60,
    '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'::UUID,
    'in_person',
    'Test Location',
    'Test booking from SQL'
  ) as test_result;

-- ============================================================================
-- PART 5: Check if trigger affected the package
-- ============================================================================

SELECT '=== CHECK TRIGGER IMPACT ===' as section;

SELECT
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions'
  AND event_object_table = 'sessions';

-- ============================================================================
-- EXPECTED DIAGNOSIS:
-- ============================================================================
-- If PART 1 shows remaining_sessions = 0:
--   → Someone/something booked a session after we synced
--   → Or trigger decremented it to 0
--
-- If PART 1 shows remaining_sessions = 1:
--   → Booking function is checking wrong package
--   → Or Flutter is passing wrong package_id
--
-- If PART 2 shows new sessions:
--   → Trigger worked and decreased count
--   → Package is now full
--
-- If PART 4 test booking succeeds:
--   → Function works, problem is in Flutter
--
-- If PART 4 test booking fails:
--   → Function has issue, need to debug further
-- ============================================================================
