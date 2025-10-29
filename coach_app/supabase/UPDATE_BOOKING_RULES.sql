-- ============================================================================
-- UPDATE BOOKING RULES TO ALLOW TODAY'S BOOKING & 7 AM - 10 PM AVAILABILITY
-- ============================================================================
-- This updates both the booking_rules table and database functions
-- to match the Flutter app logic changes
-- ============================================================================

-- STEP 1: Update global minimum advance booking rule
-- ============================================================================
-- Change from 2 hours to 0 hours (allow booking today)

UPDATE booking_rules
SET rule_value = '{"hours": 0}'::JSONB,
    updated_at = NOW()
WHERE rule_name = 'global_min_advance'
  AND rule_type = 'min_advance_hours';

-- STEP 2: Update the book_session_with_validation function
-- ============================================================================
-- Remove the 2-hour minimum advance validation

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

  -- VALIDATION 2: Check minimum advance booking (CHANGED: 0 hours = allow today)
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

COMMENT ON FUNCTION book_session_with_validation IS 'Book session with validation - Updated to allow same-day bookings (0 hours advance)';

-- STEP 3: Update get_available_slots function
-- ============================================================================
-- Change working hours from 6 AM - 10 PM to 7 AM - 10 PM
-- Remove 2-hour minimum advance check

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

  -- CHANGED: Start from 7 AM (was 6 AM)
  v_current_time := (p_date || ' 07:00:00')::TIMESTAMPTZ;
  -- Keep end at 10 PM (22:00)
  v_end_of_day := (p_date || ' 22:00:00')::TIMESTAMPTZ;

  WHILE v_current_time < v_end_of_day LOOP
    v_slot_end := v_current_time + (p_duration_minutes || ' minutes')::INTERVAL;

    -- CHANGED: Only check if time has passed (not 2 hours in advance)
    IF v_current_time <= NOW() THEN
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
        NULL::UUID, -- We don't know client yet
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

    -- Move to next 30-minute slot
    v_current_time := v_current_time + INTERVAL '30 minutes';
  END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_available_slots IS 'Get available time slots - Working hours: 7 AM - 10 PM, allows same-day booking';

-- ============================================================================
-- STEP 4: Verify the changes
-- ============================================================================

-- Show updated booking rules
SELECT
  '✅ UPDATED BOOKING RULES' as status,
  rule_name,
  rule_value->>'hours' as min_hours,
  'Allows same-day booking' as note
FROM booking_rules
WHERE rule_name = 'global_min_advance';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '🎉 Booking Rules Updated Successfully!' as message;
SELECT '' as blank;
SELECT '📋 CHANGES APPLIED:' as summary;
SELECT '✅ Minimum advance time: 2 hours → 0 hours (same-day booking allowed)' as change_1;
SELECT '✅ Working hours: 7:00 AM - 10:00 PM (22:00)' as change_2;
SELECT '✅ Double booking prevention: Still active (15-min buffer)' as change_3;
SELECT '' as blank2;
SELECT '🔄 Please refresh your Flutter app to apply changes!' as action;
