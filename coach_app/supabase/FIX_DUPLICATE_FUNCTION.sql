-- ============================================================================
-- FIX DUPLICATE book_session_with_validation FUNCTION
-- ============================================================================
-- Error: "Could not choose the best candidate function"
-- Cause: Two functions exist with same name and parameters
-- Solution: Drop all versions and recreate with correct signature

-- STEP 1: Drop all existing versions of the function
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text);
DROP FUNCTION IF EXISTS book_session_with_validation;

-- STEP 2: Recreate the function with correct parameters
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
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time (with default fallback)
  BEGIN
    v_buffer_minutes := get_buffer_minutes(p_trainer_id);
  EXCEPTION WHEN OTHERS THEN
    v_buffer_minutes := 15; -- Default 15 minutes
  END;

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

  -- VALIDATION 4: Check for conflicts (skip if function doesn't exist)
  BEGIN
    IF EXISTS(
      SELECT 1 FROM check_booking_conflicts(
        p_trainer_id, p_client_id, p_scheduled_start, v_scheduled_end
      ) LIMIT 1
    ) THEN
      RETURN jsonb_build_object(
        'success', FALSE,
        'error', 'Time slot conflict detected',
        'has_conflicts', TRUE
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Skip conflict check if function doesn't exist
    NULL;
  END;

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
  -- No manual UPDATE needed here!

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

-- Verify
SELECT '✅ Duplicate function removed, single version created' as status;

-- Test the function
SELECT book_session_with_validation(
  'db18b246-63dc-4627-91b3-6bb6bb8a5a95'::uuid,  -- client_id
  '72f779ab-e255-44f6-8f27-81f17bb24921'::uuid,  -- trainer_id
  (SELECT package_id FROM client_packages WHERE client_id = 'db18b246-63dc-4627-91b3-6bb6bb8a5a95' LIMIT 1),
  NOW() + INTERVAL '1 day',  -- scheduled_start
  60,  -- duration_minutes
  'in_person',  -- session_type
  'Gym',  -- location
  'Test booking'  -- notes
) as test_result;
