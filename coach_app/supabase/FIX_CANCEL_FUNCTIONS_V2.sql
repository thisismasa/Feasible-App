-- ============================================================================
-- FIX: Cancel session functions with ANY/ALL array operator error (V2)
-- ============================================================================
-- This version DROPS existing functions first to avoid type conflicts
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop existing cancel functions
-- ============================================================================

DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, UUID, TEXT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS cancel_session_with_reason(UUID, TEXT, UUID) CASCADE;

SELECT '✅ Old functions dropped' as step_1;

-- ============================================================================
-- STEP 2: Create cancel_session_with_refund (FIXED)
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
  v_package_id UUID;
  v_success BOOLEAN := FALSE;
  v_error TEXT := NULL;
BEGIN
  -- Get session details
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
    AND s.status IN ('scheduled', 'confirmed')  -- FIXED: Use IN instead of = ANY(ARRAY[...])
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

  -- If refund is requested and session has a package, increment the package sessions
  IF p_refund_session AND v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0),
      updated_at = NOW()
    WHERE id = v_session.package_id
      AND status = 'active';  -- FIXED: Direct comparison instead of = ANY

    RAISE NOTICE 'Session cancelled: Refunded package % (added 1 session)', v_session.package_id;
  END IF;

  v_success := TRUE;

  RETURN json_build_object(
    'success', v_success,
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
-- STEP 3: Create cancel_session_with_reason (FIXED)
-- ============================================================================

CREATE OR REPLACE FUNCTION cancel_session_with_reason(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID
)
RETURNS JSON AS $$
DECLARE
  v_session RECORD;
  v_success BOOLEAN := FALSE;
BEGIN
  -- Get session details
  SELECT
    s.id,
    s.client_id,
    s.package_id,
    s.status
  INTO v_session
  FROM sessions s
  WHERE s.id = p_session_id
    AND s.status IN ('scheduled', 'confirmed')  -- FIXED: Use IN instead of = ANY(ARRAY[...])
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

  -- Refund the package session (add back to remaining)
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

  v_success := TRUE;

  RETURN json_build_object(
    'success', v_success,
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
-- STEP 4: Grant permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION cancel_session_with_refund TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_reason TO authenticated;

SELECT '✅ Permissions granted' as step_4;

-- ============================================================================
-- STEP 5: Verify functions were created successfully
-- ============================================================================

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  '✅ Working' as status
FROM pg_proc
WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- SUCCESS! Cancel functions are now fixed
-- ============================================================================
-- Next: Test cancelling a session in Flutter UI
-- Expected: No more "op ANY/ALL (array) requires operator to yield boolean" error
-- ============================================================================
