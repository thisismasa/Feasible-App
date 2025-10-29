-- ============================================================================
-- BLOCK ADVANCE BOOKING - Only Allow Booking for TODAY
-- ============================================================================
-- This prevents trainers from booking sessions in advance (tomorrow/future)
-- Only TODAY (same day) bookings are allowed
-- ============================================================================

-- STEP 1: Update booking function to only allow TODAY
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
  v_buffer_minutes INTEGER := 15;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_conflict_count INTEGER;
  v_booking_date DATE;
  v_today_date DATE;
BEGIN
  -- Get dates for comparison
  v_booking_date := p_scheduled_start::DATE;
  v_today_date := CURRENT_DATE;

  RAISE NOTICE '⏳ Booking attempt: date=%, today=%', v_booking_date, v_today_date;

  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package
  SELECT id, client_id, total_sessions, used_sessions, remaining_sessions, status, expiry_date
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
      'message', 'This package does not belong to the selected client',
      'errors', ARRAY['Package does not belong to this client']
    );
  END IF;

  IF v_package.status != 'active' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package is not active',
      'errors', ARRAY['Package is not active']
    );
  END IF;

  IF v_package.expiry_date <= NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package expired on ' || to_char(v_package.expiry_date, 'DD Mon YYYY'),
      'errors', ARRAY['Package has expired']
    );
  END IF;

  IF v_package.remaining_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'No sessions remaining in this package',
      'errors', ARRAY['No sessions remaining in package']
    );
  END IF;

  -- ✅ NEW VALIDATION: Only allow booking for TODAY
  IF v_booking_date > v_today_date THEN
    RAISE NOTICE '❌ Advance booking blocked: trying to book % but today is %', v_booking_date, v_today_date;
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book in advance. Only TODAY bookings are allowed. Please book day-by-day.',
      'errors', ARRAY['Cannot book sessions in advance - only TODAY allowed']
    );
  END IF;

  -- VALIDATION 2: Not in past
  IF p_scheduled_start < NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book sessions in the past',
      'errors', ARRAY['Cannot book sessions in the past']
    );
  END IF;

  -- VALIDATION 3: Trainer conflicts
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (p_scheduled_start, v_scheduled_end) OVERLAPS (buffer_start, buffer_end);

  IF v_conflict_count > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Trainer has another session at this time (including 15 min buffer)',
      'errors', ARRAY['Trainer has another session at this time']
    );
  END IF;

  -- VALIDATION 4: Client conflicts
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

  RAISE NOTICE '✓ All validations passed, creating session for TODAY';

  -- CREATE SESSION
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

  -- UPDATE PACKAGE
  UPDATE client_packages
  SET
    used_sessions = used_sessions + 1,
    remaining_sessions = remaining_sessions - 1,
    updated_at = NOW()
  WHERE id = p_package_id;

  RAISE NOTICE '✅ Session created for TODAY: %', v_session_id;

  -- RETURN SUCCESS
  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'message', 'Session booked successfully for TODAY',
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
  'Book session with validation - ONLY ALLOWS BOOKING FOR TODAY (no advance booking)';


-- STEP 2: Test blocking future booking
DO $$
DECLARE
  v_result JSONB;
BEGIN
  -- Try to book tomorrow (should fail)
  v_result := book_session_with_validation(
    p_client_id := 'd3503cf5-60c5-4378-99fa-0e91efdd2f90'::UUID,
    p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID,
    p_scheduled_start := (CURRENT_DATE + INTERVAL '1 day' + INTERVAL '10 hours')::TIMESTAMPTZ,
    p_duration_minutes := 60,
    p_package_id := '6d9641c2-0389-4f1e-ba4c-9d8689cc960a'::UUID,
    p_session_type := 'in_person'
  );

  RAISE NOTICE '========== TEST: Booking Tomorrow ==========';
  RAISE NOTICE 'Result: %', v_result;
  RAISE NOTICE 'Expected: success = FALSE (blocked)';
  RAISE NOTICE 'Actual: success = %', v_result->>'success';

  IF (v_result->>'success')::BOOLEAN = FALSE THEN
    RAISE NOTICE '✅ CORRECT: Tomorrow booking was BLOCKED';
  ELSE
    RAISE NOTICE '❌ WRONG: Tomorrow booking was ALLOWED (should be blocked!)';
  END IF;
END $$;


-- STEP 3: Test allowing today booking
DO $$
DECLARE
  v_result JSONB;
BEGIN
  -- Try to book today (should succeed if time is in future)
  v_result := book_session_with_validation(
    p_client_id := 'd3503cf5-60c5-4378-99fa-0e91efdd2f90'::UUID,
    p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID,
    p_scheduled_start := (CURRENT_DATE + INTERVAL '22 hours')::TIMESTAMPTZ,
    p_duration_minutes := 60,
    p_package_id := '6d9641c2-0389-4f1e-ba4c-9d8689cc960a'::UUID,
    p_session_type := 'in_person'
  );

  RAISE NOTICE '========== TEST: Booking Today ==========';
  RAISE NOTICE 'Result: %', v_result;
  RAISE NOTICE 'Expected: success = TRUE (allowed) or conflict/past error';
  RAISE NOTICE 'Actual: success = %', v_result->>'success';
  RAISE NOTICE 'Message: %', v_result->>'message';

  IF (v_result->>'success')::BOOLEAN = TRUE THEN
    RAISE NOTICE '✅ CORRECT: Today booking was ALLOWED';
  ELSE
    RAISE NOTICE 'ℹ️  Today booking failed: %', v_result->>'message';
  END IF;
END $$;


-- STEP 4: Show current booking policy
SELECT
  '========================================' as message
UNION ALL SELECT '✅ BOOKING POLICY UPDATED'
UNION ALL SELECT '========================================'
UNION ALL SELECT 'NEW RULE: Only TODAY bookings allowed'
UNION ALL SELECT ''
UNION ALL SELECT 'ALLOWED:'
UNION ALL SELECT '  ✅ Book session for TODAY (same day)'
UNION ALL SELECT '  ✅ Any time slot today (if not in past)'
UNION ALL SELECT ''
UNION ALL SELECT 'BLOCKED:'
UNION ALL SELECT '  ❌ Book session for TOMORROW'
UNION ALL SELECT '  ❌ Book session for ANY future date'
UNION ALL SELECT '  ❌ Advance booking disabled'
UNION ALL SELECT ''
UNION ALL SELECT 'NEXT STEPS:'
UNION ALL SELECT '1. Update Flutter app calendar'
UNION ALL SELECT '2. Disable future dates in calendar widget'
UNION ALL SELECT '3. Show message: "Only TODAY booking allowed"';
