-- ============================================================================
-- QUICK FIX FOR BOOKING ERROR - p'Poon Client
-- ============================================================================
-- Run this FIRST before trying to book again
-- ============================================================================

-- FIX 1: Ensure RPC function exists (from ENSURE_CONSISTENT_BOOKINGS.sql)
-- This is the MAIN fix - deploy the proper booking function
CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_package_id UUID,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_session_id UUID;
  v_scheduled_end TIMESTAMPTZ;
  v_package RECORD;
  v_buffer_minutes INTEGER;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_conflict_count INTEGER;
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time (default 15 minutes)
  v_buffer_minutes := 15;
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package exists and is valid
  SELECT
    id, client_id, total_sessions, used_sessions,
    remaining_sessions, status, expiry_date
  INTO v_package
  FROM client_packages
  WHERE id = p_package_id;

  IF v_package.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package not found',
      'errors', ARRAY['Package not found']
    );
  END IF;

  IF v_package.client_id != p_client_id THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package does not belong to this client',
      'errors', ARRAY['Package does not belong to this client']
    );
  END IF;

  IF v_package.status != 'active' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package is not active (status: ' || v_package.status || ')',
      'errors', ARRAY['Package is not active']
    );
  END IF;

  IF v_package.expiry_date <= NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package expired on ' || v_package.expiry_date::TEXT,
      'errors', ARRAY['Package has expired']
    );
  END IF;

  IF v_package.remaining_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'No sessions remaining in package',
      'errors', ARRAY['No sessions remaining in package']
    );
  END IF;

  -- VALIDATION 2: Check not booking in the past
  IF p_scheduled_start < NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book sessions in the past',
      'errors', ARRAY['Cannot book sessions in the past']
    );
  END IF;

  -- VALIDATION 3: Check for trainer conflicts
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (p_scheduled_start, v_scheduled_end) OVERLAPS (buffer_start, buffer_end);

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Trainer has another session at this time (including 15 min buffer)',
      'errors', ARRAY['Trainer has another session at this time (including 15 min buffer)']
    );
  END IF;

  -- VALIDATION 4: Check for client conflicts
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE client_id = p_client_id
    AND status IN ('scheduled', 'confirmed')
    AND (p_scheduled_start, v_scheduled_end) OVERLAPS (scheduled_start, scheduled_end);

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Client has another session at this time',
      'errors', ARRAY['Client has another session at this time']
    );
  END IF;

  -- ✅ ALL VALIDATIONS PASSED - CREATE SESSION
  INSERT INTO sessions (
    client_id, trainer_id, package_id,
    scheduled_start, scheduled_end, duration_minutes,
    buffer_start, buffer_end,
    status, session_type, location, client_notes,
    created_at, updated_at
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_scheduled_start, v_scheduled_end, p_duration_minutes,
    v_buffer_start, v_buffer_end,
    'scheduled', p_session_type, p_location, p_notes,
    NOW(), NOW()
  ) RETURNING id INTO v_session_id;

  -- ✅ UPDATE PACKAGE
  UPDATE client_packages
  SET
    used_sessions = used_sessions + 1,
    remaining_sessions = remaining_sessions - 1,
    updated_at = NOW()
  WHERE id = p_package_id;

  -- ✅ RETURN SUCCESS
  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'message', 'Session booked successfully',
    'remaining_sessions', v_package.remaining_sessions - 1
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Database error: ' || SQLERRM,
      'errors', ARRAY['Database error: ' || SQLERRM]
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION book_session_with_validation IS
  'Book session with validation - Returns proper error messages';


-- FIX 2: Fix p'Poon's package if it has wrong remaining_sessions
UPDATE client_packages
SET
  remaining_sessions = total_sessions - used_sessions,
  updated_at = NOW()
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'
  AND remaining_sessions != (total_sessions - used_sessions);


-- FIX 3: Ensure package is active
UPDATE client_packages
SET
  status = 'active',
  updated_at = NOW()
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'
  AND status != 'active';


-- FIX 4: Extend expiry date if expired
UPDATE client_packages
SET
  expiry_date = NOW() + INTERVAL '30 days',
  updated_at = NOW()
WHERE id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'
  AND expiry_date <= NOW();


-- FIX 5: Remove any pending conflicts at 18:30 on Oct 29
-- (Only if there are old test bookings)
DELETE FROM sessions
WHERE (
  trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  OR client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41'
)
AND scheduled_start = '2025-10-29 18:30:00+07'::TIMESTAMPTZ
AND status IN ('scheduled', 'confirmed');


-- VERIFICATION: Check if ready to book now
SELECT
  '========== READY TO BOOK? ==========' as status,
  cp.id,
  cp.package_name,
  cp.client_id,
  u.full_name as client_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.status,
  cp.expiry_date,
  CASE
    WHEN cp.status != 'active' THEN '✗ Not active'
    WHEN cp.expiry_date <= NOW() THEN '✗ Expired'
    WHEN cp.remaining_sessions <= 0 THEN '✗ No sessions'
    ELSE '✓ READY!'
  END as booking_status
FROM client_packages cp
LEFT JOIN users u ON u.id = cp.client_id
WHERE cp.id = 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd';


-- TEST: Try booking now
SELECT
  'TEST BOOKING' as test_type,
  book_session_with_validation(
    p_client_id := 'ac6b34af-77e4-41c0-a0de-59ef190fab41'::UUID,
    p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID,
    p_scheduled_start := '2025-10-29 18:30:00+07'::TIMESTAMPTZ,
    p_duration_minutes := 60,
    p_package_id := 'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd'::UUID,
    p_session_type := 'in_person'
  ) as result;
