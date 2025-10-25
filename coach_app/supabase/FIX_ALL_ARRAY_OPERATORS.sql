-- ============================================================================
-- FIX: All ANY/ALL Array Operator Errors Across All Functions
-- ============================================================================
-- This fixes ANY/ALL array operator issues in ALL database functions
-- Error: "op ANY/ALL (array) requires operator to yield boolean"
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop all potentially problematic functions
-- ============================================================================

DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, UUID, TEXT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS cancel_session_with_reason(UUID, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

SELECT '✅ Old functions dropped' as step_1;

-- ============================================================================
-- STEP 2: Recreate cancel_session_with_refund (FIXED)
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_session_with_refund(
  p_session_id UUID,
  p_cancelled_by UUID,
  p_reason TEXT DEFAULT NULL,
  p_refund_session BOOLEAN DEFAULT TRUE
)
RETURNS JSON AS $$
DECLARE
  v_session RECORD;
BEGIN
  -- Get session details - FIXED: Use IN instead of ANY
  SELECT
    s.id,
    s.client_id,
    s.trainer_id,
    s.package_id,
    s.status,
    s.scheduled_start
  INTO v_session
  FROM sessions s
  WHERE s.id = p_session_id
    AND s.status IN ('scheduled', 'confirmed')  -- FIXED!
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or not cancellable'
    );
  END IF;

  -- Update session status
  UPDATE sessions
  SET
    status = 'cancelled',
    notes = COALESCE(notes || E'\n\n', '') || 'Cancelled: ' || COALESCE(p_reason, 'No reason provided'),
    updated_at = NOW()
  WHERE id = p_session_id;

  -- Refund package session if applicable
  IF p_refund_session AND v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0),
      updated_at = NOW()
    WHERE id = v_session.package_id
      AND status = 'active';  -- FIXED: Direct comparison

    RAISE NOTICE 'Session cancelled: Refunded package % (added 1 session)', v_session.package_id;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'session_id', p_session_id,
    'refunded', p_refund_session
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '✅ cancel_session_with_refund created' as step_2;

-- ============================================================================
-- STEP 3: Recreate cancel_session_with_reason (FIXED)
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_session_with_reason(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID
)
RETURNS JSON AS $$
DECLARE
  v_session RECORD;
BEGIN
  -- Get session details - FIXED: Use IN instead of ANY
  SELECT
    s.id,
    s.client_id,
    s.package_id,
    s.status
  INTO v_session
  FROM sessions s
  WHERE s.id = p_session_id
    AND s.status IN ('scheduled', 'confirmed')  -- FIXED!
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or not cancellable'
    );
  END IF;

  -- Update session to cancelled
  UPDATE sessions
  SET
    status = 'cancelled',
    notes = COALESCE(notes || E'\n\n', '') || 'Cancelled by: ' || p_cancelled_by::TEXT || E'\nReason: ' || p_cancellation_reason,
    updated_at = NOW()
  WHERE id = p_session_id;

  -- Refund package session
  IF v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0),
      updated_at = NOW()
    WHERE id = v_session.package_id
      AND status = 'active';

    RAISE NOTICE 'Session cancelled: Refunded package % (added 1 session)', v_session.package_id;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'session_id', p_session_id
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '✅ cancel_session_with_reason created' as step_3;

-- ============================================================================
-- STEP 4: Recreate book_session_with_validation (ensure no ANY/ALL issues)
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
)
RETURNS JSON AS $$
DECLARE
  v_package_sessions INTEGER;
  v_scheduled_end TIMESTAMPTZ;
  v_new_session_id UUID;
BEGIN
  -- Calculate end time
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Check package has remaining sessions
  SELECT cp.remaining_sessions
  INTO v_package_sessions
  FROM client_packages cp
  WHERE cp.id = p_package_id
    AND cp.client_id = p_client_id
    AND cp.status = 'active'  -- FIXED: Direct comparison
  LIMIT 1;

  IF v_package_sessions IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Package not found or inactive',
      'message', 'Package not found or inactive'
    );
  END IF;

  IF v_package_sessions <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'No remaining sessions in package',
      'message', 'No remaining sessions in package'
    );
  END IF;

  -- Create session
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    session_type,
    location,
    notes,
    status,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    p_scheduled_start,
    v_scheduled_end,
    p_duration_minutes,
    p_session_type,
    p_location,
    p_notes,
    'scheduled',
    NOW(),
    NOW()
  )
  RETURNING id INTO v_new_session_id;

  RETURN json_build_object(
    'success', TRUE,
    'session_id', v_new_session_id,
    'message', 'Session booked successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'message', 'Failed to book session: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '✅ book_session_with_validation created' as step_4;

-- ============================================================================
-- STEP 5: Grant permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION cancel_session_with_refund TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_reason TO authenticated;
GRANT EXECUTE ON FUNCTION book_session_with_validation TO authenticated;

SELECT '✅ Permissions granted' as step_5;

-- ============================================================================
-- STEP 6: Verify all functions
-- ============================================================================

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prorettype::regtype as return_type,
  '✅ Ready' as status
FROM pg_proc
WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason', 'book_session_with_validation')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- SUCCESS! All functions fixed
-- ============================================================================
-- Next: Restart Flutter app (hot reload won't work for database changes)
-- Command: taskkill /F /IM dart.exe && flutter run -d chrome --web-port=8100
-- ============================================================================
