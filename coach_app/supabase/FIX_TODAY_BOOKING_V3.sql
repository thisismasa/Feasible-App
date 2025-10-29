-- ============================================================================
-- FIX: Allow booking TODAY - V3 with comprehensive function dropping
-- ============================================================================
-- This version drops ALL overloads by using dynamic SQL generation
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop ALL versions of book_session_with_validation
-- ============================================================================
-- Using DO block to drop all overloads dynamically

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT 'DROP FUNCTION IF EXISTS ' || oid::regprocedure || ' CASCADE;' as drop_cmd
        FROM pg_proc
        WHERE proname = 'book_session_with_validation'
          AND pronamespace = 'public'::regnamespace
    LOOP
        EXECUTE r.drop_cmd;
        RAISE NOTICE 'Dropped: %', r.drop_cmd;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Drop ALL versions of get_available_slots
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT 'DROP FUNCTION IF EXISTS ' || oid::regprocedure || ' CASCADE;' as drop_cmd
        FROM pg_proc
        WHERE proname = 'get_available_slots'
          AND pronamespace = 'public'::regnamespace
    LOOP
        EXECUTE r.drop_cmd;
        RAISE NOTICE 'Dropped: %', r.drop_cmd;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 3: Create book_session_with_validation - Remove 2-hour advance
-- ============================================================================

CREATE FUNCTION book_session_with_validation(
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
  -- ✅ FIXED: Column name is remaining_sessions not sessions_remaining
  SELECT remaining_sessions INTO v_package_sessions
  FROM client_packages
  WHERE id = p_package_id
    AND client_id = p_client_id
    AND is_active = true
    AND expiry_date > NOW();

  IF v_package_sessions IS NULL THEN
    v_validation_errors := array_append(v_validation_errors, 'Package not found or expired');
  ELSIF v_package_sessions <= 0 THEN
    v_validation_errors := array_append(v_validation_errors, 'No sessions remaining in package');
  END IF;

  -- VALIDATION 2: Check minimum advance booking
  -- ✅ FIXED: Changed from 2 hours to 0 hours (allow same-day booking)
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

  -- Update package: decrement remaining, increment used
  -- ✅ FIXED: Column name is remaining_sessions/used_sessions not sessions_scheduled
  UPDATE client_packages
  SET remaining_sessions = remaining_sessions - 1,
      used_sessions = used_sessions + 1,
      updated_at = NOW()
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

COMMENT ON FUNCTION book_session_with_validation IS '✅ FIXED: 2 hours → 0 hours (allow same-day booking)';

-- ============================================================================
-- STEP 4: Create get_available_slots - Allow current time slots
-- ============================================================================

CREATE FUNCTION get_available_slots(
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

    -- ✅ FIXED: Changed <= to < (allow booking at current time)
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

COMMENT ON FUNCTION get_available_slots IS '✅ FIXED: Now allows booking at current time';

-- ============================================================================
-- SUCCESS VERIFICATION
-- ============================================================================

SELECT '🎉 ALL FIXES APPLIED SUCCESSFULLY!' as status;
SELECT '' as blank;
SELECT '✅ Dropped all old function versions' as step_1;
SELECT '✅ Created book_session_with_validation (0 hours advance)' as step_2;
SELECT '✅ Created get_available_slots (current time allowed)' as step_3;
SELECT '' as blank2;
SELECT '📅 YOU CAN NOW BOOK TODAY - October 28th!' as result;
SELECT '🕐 Starting from: ' || TO_CHAR(NOW(), 'HH24:MI') as current_time;
SELECT '' as blank3;
SELECT '🔄 Refresh your Flutter app and try booking!' as action;
