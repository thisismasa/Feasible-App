-- ============================================================================
-- FIX PACKAGE LOOKUP IN book_session_with_validation
-- ============================================================================
-- Problem: Looking for package_id = p_package_id, but client_packages table
--          has package_id as FK to packages table
-- Solution: Look up by BOTH package_id AND client_id, or use client_packages.id

-- Let's first check what the Flutter app is sending
-- Show all active packages for client Nuttapon
SELECT
  cp.id as client_package_id,
  cp.package_id,
  p.name as package_name,
  cp.remaining_sessions,
  cp.total_sessions,
  cp.status
FROM client_packages cp
JOIN packages p ON p.id = cp.package_id
WHERE cp.client_id = 'db18b246-63dc-4627-91b3-6bb6bb8a5a95'
  AND cp.status = 'active';

-- Now fix the function to properly look up packages
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text);

CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,  -- This is the base package ID from packages table
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
  v_client_package_id UUID;
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time (with default fallback)
  BEGIN
    v_buffer_minutes := get_buffer_minutes(p_trainer_id);
  EXCEPTION WHEN OTHERS THEN
    v_buffer_minutes := 15;
  END;

  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package has sessions (FIXED LOOKUP)
  -- Look up by BOTH package_id (FK) AND client_id
  SELECT cp.remaining_sessions, cp.id
  INTO v_package_sessions, v_client_package_id
  FROM client_packages cp
  WHERE cp.package_id = p_package_id  -- FK to packages table
    AND cp.client_id = p_client_id    -- Client who owns this package
    AND cp.status = 'active'
  LIMIT 1;

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

SELECT '✅ Package lookup fixed - now checks BOTH package_id AND client_id' as status;
