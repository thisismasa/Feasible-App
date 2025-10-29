-- ============================================================================
-- DIAGNOSE BOOKING FAILURE FOR P"POON
-- ============================================================================
-- Check why booking is failing but session appears in booking management
-- ============================================================================

SELECT '========== CHECK 1: Client Package State ==========' as check;
SELECT
  cp.id as package_id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.status,
  cp.is_active,
  cp.expiry_date,
  cp.expiry_date > NOW() as not_expired,
  cp.purchase_date,
  u.full_name as client_name
FROM client_packages cp
JOIN users u ON u.id = cp.client_id
WHERE cp.client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
ORDER BY cp.created_at DESC;

SELECT '========== CHECK 2: Sessions for Poon ==========' as check;
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.status,
  s.session_type,
  s.location,
  s.package_id,
  s.created_at,
  cp.package_name,
  cp.remaining_sessions as package_remaining
FROM sessions s
LEFT JOIN client_packages cp ON cp.id = s.package_id
WHERE s.client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
ORDER BY s.created_at DESC
LIMIT 5;

SELECT '========== CHECK 3: Test Booking Validation ==========' as check;
-- Try to book a session and see what errors we get
SELECT book_session_with_validation(
  p_client_id := 'ac6b34af-77e4-41c0-a0de-59ef190fab41',
  p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921',
  p_scheduled_start := NOW() + INTERVAL '1 hour',
  p_duration_minutes := 60,
  p_package_id := (
    SELECT id FROM client_packages
    WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
      AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1
  ),
  p_session_type := 'in_person',
  p_location := 'Test Location',
  p_notes := 'Test booking'
) as test_result;

SELECT '========== CHECK 4: Validation Details ==========' as check;
-- Check specific validation conditions
SELECT
  cp.id,
  cp.package_name,
  cp.remaining_sessions,
  cp.is_active,
  cp.expiry_date,
  cp.expiry_date > NOW() as not_expired,
  CASE
    WHEN cp.remaining_sessions IS NULL THEN 'Package not found'
    WHEN cp.remaining_sessions <= 0 THEN 'No sessions remaining'
    WHEN NOT cp.is_active THEN 'Package not active'
    WHEN cp.expiry_date <= NOW() THEN 'Package expired'
    ELSE 'Package is valid'
  END as validation_status
FROM client_packages cp
WHERE cp.client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
  AND cp.is_active = true
ORDER BY cp.created_at DESC
LIMIT 1;

SELECT '========== SUMMARY ==========' as check;
SELECT
  (SELECT COUNT(*) FROM client_packages WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41' AND is_active = true) as active_packages,
  (SELECT SUM(remaining_sessions) FROM client_packages WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41' AND is_active = true) as total_remaining_sessions,
  (SELECT COUNT(*) FROM sessions WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41' AND status = 'scheduled') as scheduled_sessions,
  (SELECT COUNT(*) FROM sessions WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41' AND scheduled_start >= NOW()) as future_sessions;
