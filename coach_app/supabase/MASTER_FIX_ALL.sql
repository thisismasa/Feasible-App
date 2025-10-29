-- ============================================================================
-- MASTER FIX - Apply ALL Fixes in Correct Order
-- ============================================================================
-- This combines:
-- 1. Schema sync (fix column names and add missing columns)
-- 2. Booking fixes (allow today, correct function logic)
-- ============================================================================
-- Run this ONCE in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- PART 1: SCHEMA SYNC - Fix Column Names and Add Missing Columns
-- ============================================================================

-- Fix client_packages table
DO $$
BEGIN
  -- Add sessions_used (alias for used_sessions)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_packages' AND column_name = 'sessions_used') THEN
    ALTER TABLE client_packages ADD COLUMN sessions_used INTEGER GENERATED ALWAYS AS (used_sessions) STORED;
  END IF;

  -- Add amount_paid (alias for price_paid)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_packages' AND column_name = 'amount_paid') THEN
    ALTER TABLE client_packages ADD COLUMN amount_paid DECIMAL(10,2) GENERATED ALWAYS AS (price_paid) STORED;
  END IF;

  -- Add status (computed column)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_packages' AND column_name = 'status') THEN
    ALTER TABLE client_packages ADD COLUMN status TEXT GENERATED ALWAYS AS (
      CASE
        WHEN NOT is_active THEN 'expired'
        WHEN expiry_date IS NOT NULL AND expiry_date < NOW() THEN 'expired'
        WHEN remaining_sessions <= 0 THEN 'completed'
        ELSE 'active'
      END
    ) STORED;
  END IF;

  -- Add payment_status
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'client_packages' AND column_name = 'payment_status') THEN
    ALTER TABLE client_packages ADD COLUMN payment_status TEXT DEFAULT 'paid';
  END IF;
END $$;

-- ============================================================================
-- PART 2: DROP OLD BOOKING FUNCTIONS
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all versions of book_session_with_validation
    FOR r IN
        SELECT 'DROP FUNCTION IF EXISTS ' || oid::regprocedure || ' CASCADE;' as drop_cmd
        FROM pg_proc
        WHERE proname = 'book_session_with_validation' AND pronamespace = 'public'::regnamespace
    LOOP
        EXECUTE r.drop_cmd;
    END LOOP;

    -- Drop all versions of get_available_slots
    FOR r IN
        SELECT 'DROP FUNCTION IF EXISTS ' || oid::regprocedure || ' CASCADE;' as drop_cmd
        FROM pg_proc
        WHERE proname = 'get_available_slots' AND pronamespace = 'public'::regnamespace
    LOOP
        EXECUTE r.drop_cmd;
    END LOOP;
END $$;

-- ============================================================================
-- PART 3: CREATE CORRECT BOOKING FUNCTIONS WITH FIXED COLUMN NAMES
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
  v_buffer_minutes := get_buffer_minutes(p_trainer_id);
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package (FIXED: use remaining_sessions and is_active)
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

  -- VALIDATION 2: Check minimum advance (FIXED: 0 hours, allow today)
  IF p_scheduled_start < NOW() THEN
    v_validation_errors := array_append(v_validation_errors, 'Cannot book sessions in the past');
  END IF;

  -- VALIDATION 3: Check maximum advance
  IF p_scheduled_start > NOW() + INTERVAL '90 days' THEN
    v_validation_errors := array_append(v_validation_errors, 'Cannot book more than 90 days in advance');
  END IF;

  -- VALIDATION 4: Check conflicts
  FOR v_conflict IN
    SELECT * FROM check_booking_conflicts(p_trainer_id, p_client_id, p_scheduled_start, v_scheduled_end)
  LOOP
    v_has_conflicts := TRUE;
    v_validation_errors := array_append(v_validation_errors, v_conflict.conflict_description);
  END LOOP;

  IF array_length(v_validation_errors, 1) > 0 THEN
    RETURN jsonb_build_object('success', FALSE, 'errors', v_validation_errors, 'has_conflicts', v_has_conflicts);
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

  -- UPDATE PACKAGE (FIXED: use remaining_sessions and used_sessions)
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

-- ============================================================================
-- PART 4: CREATE get_available_slots (FIXED: allow current time)
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
  v_current_time := (p_date || ' 07:00:00')::TIMESTAMPTZ;
  v_end_of_day := (p_date || ' 22:00:00')::TIMESTAMPTZ;

  WHILE v_current_time < v_end_of_day LOOP
    v_slot_end := v_current_time + (p_duration_minutes || ' minutes')::INTERVAL;

    -- FIXED: Changed <= to < (allow booking at current time)
    IF v_current_time < NOW() THEN
      RETURN QUERY SELECT v_current_time, v_slot_end, FALSE, 'Time has already passed'::TEXT;
    ELSE
      SELECT COUNT(*) INTO v_conflicts
      FROM check_booking_conflicts(p_trainer_id, NULL::UUID, v_current_time, v_slot_end);

      IF v_conflicts > 0 THEN
        RETURN QUERY SELECT v_current_time, v_slot_end, FALSE, 'Trainer unavailable (conflict or buffer)'::TEXT;
      ELSE
        RETURN QUERY SELECT v_current_time, v_slot_end, TRUE, 'Available'::TEXT;
      END IF;
    END IF;

    v_current_time := v_current_time + INTERVAL '30 minutes';
  END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- SUCCESS VERIFICATION
-- ============================================================================

SELECT '🎉 MASTER FIX COMPLETE!' as status;
SELECT '' as blank;
SELECT '📋 FIXES APPLIED:' as summary;
SELECT '' as blank2;
SELECT '✅ SCHEMA SYNC:' as section_1;
SELECT '   • client_packages: sessions_used, amount_paid, status, payment_status' as fix_1a;
SELECT '   • Now matches Flutter ClientPackage model' as fix_1b;
SELECT '' as blank3;
SELECT '✅ BOOKING FUNCTIONS:' as section_2;
SELECT '   • book_session_with_validation: Uses remaining_sessions, is_active' as fix_2a;
SELECT '   • Allows same-day booking (0 hours advance)' as fix_2b;
SELECT '   • get_available_slots: Changed <= to < (allow current time)' as fix_2c;
SELECT '' as blank4;
SELECT '📅 YOU CAN NOW:' as can_do;
SELECT '   • Book today (October 28th)' as can_1;
SELECT '   • Book at current time or later' as can_2;
SELECT '   • App won''t crash on column errors' as can_3;
SELECT '' as blank5;
SELECT '🔄 NEXT: Hot restart Flutter app (press R)' as action;
