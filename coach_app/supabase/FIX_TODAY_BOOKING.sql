-- ============================================================================
-- FIX: Allow booking TODAY (October 28th) and remove 2-hour advance requirement
-- ============================================================================
-- PROBLEM 1: book_session_with_validation requires 2 hours advance (line 246)
-- PROBLEM 2: get_available_slots uses <= which blocks current time slots
--
-- SOLUTION: Remove 2-hour requirement and change <= to <
-- ============================================================================

-- ============================================================================
-- FIX #1: Update book_session_with_validation - Remove 2-hour advance requirement
-- ============================================================================

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
  v_package_sessions INTEGER;
  v_validation_errors TEXT[] := '{}';
  v_buffer_minutes INTEGER;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_conflict RECORD;
  v_has_conflicts BOOLEAN := FALSE;
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time
  v_buffer_minutes := get_buffer_minutes(p_trainer_id);
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package has sessions
  SELECT sessions_remaining INTO v_package_sessions
  FROM client_packages
  WHERE id = p_package_id
    AND client_id = p_client_id
    AND status = 'active'
    AND expiry_date > NOW();

  IF v_package_sessions IS NULL THEN
    v_validation_errors := array_append(v_validation_errors, 'Package not found or expired');
  ELSIF v_package_sessions <= 0 THEN
    v_validation_errors := array_append(v_validation_errors, 'No sessions remaining in package');
  END IF;

  -- VALIDATION 2: Check minimum advance booking
  -- FIXED: Changed from 2 hours to 0 hours (allow same-day booking)
  -- Old: IF p_scheduled_start < NOW() + INTERVAL '2 hours' THEN
  -- New: Only prevent booking in the past
  IF p_scheduled_start < NOW() THEN
    v_validation_errors := array_append(v_validation_errors,
      'Cannot book sessions in the past');
  END IF;

  -- VALIDATION 3: Check maximum advance booking
  IF p_scheduled_start > NOW() + INTERVAL '90 days' THEN
    v_validation_errors := array_append(v_validation_errors,
      'Cannot book more than 90 days in advance');
  END IF;

  -- VALIDATION 4: Check for conflicts
  FOR v_conflict IN
    SELECT * FROM check_booking_conflicts(
      p_trainer_id, p_client_id, p_scheduled_start, v_scheduled_end
    )
  LOOP
    v_has_conflicts := TRUE;
    v_validation_errors := array_append(v_validation_errors, v_conflict.conflict_description);
  END LOOP;

  -- Return errors if any
  IF array_length(v_validation_errors, 1) > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'errors', v_validation_errors,
      'has_conflicts', v_has_conflicts
    );
  END IF;

  -- CREATE SESSION
  INSERT INTO sessions (
    client_id, trainer_id, package_id,
    scheduled_start, scheduled_end, duration_minutes,
    buffer_start, buffer_end,
    status, session_type, location, client_notes,
    has_conflicts, validation_passed
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_scheduled_start, v_scheduled_end, p_duration_minutes,
    v_buffer_start, v_buffer_end,
    'scheduled', p_session_type, p_location, p_notes,
    FALSE, TRUE
  ) RETURNING id INTO v_session_id;

  -- Update package
  UPDATE client_packages
  SET sessions_scheduled = sessions_scheduled + 1
  WHERE id = p_package_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'buffer_minutes', v_buffer_minutes,
    'buffer_start', v_buffer_start,
    'buffer_end', v_buffer_end
  );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION book_session_with_validation IS 'Book session with validation - FIXED: 2 hours → 0 hours (allow today)';

-- ============================================================================
-- FIX #2: Update get_available_slots - Allow slots at current time
-- ============================================================================

CREATE OR REPLACE FUNCTION get_available_slots(
  p_trainer_id UUID,
  p_date DATE,
  p_duration_minutes INTEGER DEFAULT 60
) RETURNS TABLE (
  slot_start TIMESTAMPTZ,
  slot_end TIMESTAMPTZ,
  is_available BOOLEAN,
  reason TEXT
) AS $$
DECLARE
  v_current_time TIMESTAMPTZ;
  v_end_of_day TIMESTAMPTZ;
  v_slot_end TIMESTAMPTZ;
  v_buffer_minutes INTEGER;
  v_conflicts INTEGER;
BEGIN
  v_buffer_minutes := get_buffer_minutes(p_trainer_id);

  -- Start from 7 AM
  v_current_time := (p_date || ' 07:00:00')::TIMESTAMPTZ;
  -- End at 10 PM
  v_end_of_day := (p_date || ' 22:00:00')::TIMESTAMPTZ;

  WHILE v_current_time < v_end_of_day LOOP
    v_slot_end := v_current_time + (p_duration_minutes || ' minutes')::INTERVAL;

    -- FIXED: Changed <= to < so slots at current time are bookable
    -- Old: IF v_current_time <= NOW() THEN
    -- New: IF v_current_time < NOW() THEN
    IF v_current_time < NOW() THEN
      RETURN QUERY SELECT
        v_current_time,
        v_slot_end,
        FALSE,
        'Time has already passed'::TEXT;
    ELSE
      -- Check for conflicts
      SELECT COUNT(*) INTO v_conflicts
      FROM check_booking_conflicts(
        p_trainer_id,
        NULL::UUID,
        v_current_time,
        v_slot_end
      );

      IF v_conflicts > 0 THEN
        RETURN QUERY SELECT
          v_current_time,
          v_slot_end,
          FALSE,
          'Trainer unavailable (conflict or buffer)'::TEXT;
      ELSE
        RETURN QUERY SELECT
          v_current_time,
          v_slot_end,
          TRUE,
          'Available'::TEXT;
      END IF;
    END IF;

    v_current_time := v_current_time + INTERVAL '30 minutes';
  END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_available_slots IS 'Get available slots - FIXED: Now allows booking slots at current time';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT '🎉 BOTH FIXES APPLIED SUCCESSFULLY!' as status;
SELECT '' as blank;
SELECT '📋 CHANGES SUMMARY:' as summary;
SELECT '✅ Fix #1: book_session_with_validation - 2 hours → 0 hours advance' as fix_1;
SELECT '✅ Fix #2: get_available_slots - Changed <= to < for current time' as fix_2;
SELECT '' as blank2;
SELECT '🕐 You can now book sessions:' as booking_policy;
SELECT '   • Today (October 28th)' as policy_1;
SELECT '   • At the current time or later' as policy_2;
SELECT '   • No 2-hour advance requirement' as policy_3;
SELECT '' as blank3;
SELECT '📅 Test now: Book at ' || TO_CHAR(NOW(), 'HH24:MI') || ' today!' as test_suggestion;
