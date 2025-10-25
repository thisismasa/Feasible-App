-- ============================================================================
-- FIX book_session_with_validation function to use correct column names
-- ============================================================================
-- Issue: Function references wrong column names (sessions_remaining vs remaining_sessions)
-- Fix: Update function to use actual schema columns from client_packages table

CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_session_id UUID;
  v_scheduled_end TIMESTAMPTZ;
  v_buffer_minutes INTEGER;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_package_sessions INTEGER;
  v_validation_errors TEXT[] := '{}';
  v_has_conflicts BOOLEAN := FALSE;
  v_conflict RECORD;
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time
  v_buffer_minutes := COALESCE(get_buffer_minutes(p_trainer_id), 15);
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package has sessions (FIXED COLUMN NAME)
  SELECT remaining_sessions INTO v_package_sessions
  FROM client_packages
  WHERE package_id = p_package_id
    AND client_id = p_client_id
    AND status = 'active';

  IF v_package_sessions IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Package not found or inactive',
      'has_conflicts', FALSE
    );
  ELSIF v_package_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'No sessions remaining in package',
      'has_conflicts', FALSE
    );
  END IF;

  -- VALIDATION 2: Check minimum advance booking
  IF p_scheduled_start < NOW() + INTERVAL '2 hours' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Booking must be at least 2 hours in advance',
      'has_conflicts', FALSE
    );
  END IF;

  -- VALIDATION 3: Check maximum advance booking
  IF p_scheduled_start > NOW() + INTERVAL '90 days' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Cannot book more than 90 days in advance',
      'has_conflicts', FALSE
    );
  END IF;

  -- VALIDATION 4: Check for conflicts
  IF EXISTS(SELECT 1 FROM check_booking_conflicts(
    p_trainer_id, p_client_id, p_scheduled_start, v_scheduled_end
  )) THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error', 'Time slot conflict detected',
      'has_conflicts', TRUE
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
    'scheduled',
    COALESCE(p_session_type, 'in_person'),
    p_location,
    p_notes,
    FALSE, TRUE
  ) RETURNING id INTO v_session_id;

  -- Note: Package updates are handled by auto_sync_package_sessions trigger
  -- No manual UPDATE needed here anymore!

  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'buffer_minutes', v_buffer_minutes,
    'buffer_start', v_buffer_start,
    'buffer_end', v_buffer_end
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', FALSE,
    'error', SQLERRM,
    'has_conflicts', FALSE
  );
END;
$$ LANGUAGE plpgsql;

-- Verify the function
SELECT '✅ book_session_with_validation function updated with correct column names' as status;
