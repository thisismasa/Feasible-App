-- ============================================================================
-- FORCE DROP: Remove ALL cancel functions and recreate cleanly
-- ============================================================================

SELECT '=== STEP 1: Show ALL cancel_session functions ===' as step;

SELECT
  proname as function_name,
  oidvectortypes(proargtypes) as arg_types,
  pg_get_function_arguments(oid) as parameters,
  '👆 All versions that exist' as note
FROM pg_proc
WHERE proname LIKE 'cancel_session%'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- STEP 2: Drop using CASCADE to force removal
-- ============================================================================

SELECT '=== STEP 2: Force dropping ALL cancel functions ===' as step;

-- Use CASCADE to drop all dependencies
DROP FUNCTION IF EXISTS cancel_session_with_refund CASCADE;
DROP FUNCTION IF EXISTS cancel_session_with_reason CASCADE;
DROP FUNCTION IF EXISTS cancel_session_with_policy CASCADE;

-- Also try with explicit signatures
DROP FUNCTION IF EXISTS cancel_session_with_refund(p_session_id UUID, p_cancelled_by UUID, p_reason TEXT) CASCADE;
DROP FUNCTION IF EXISTS cancel_session_with_reason(p_session_id UUID, p_cancellation_reason TEXT, p_cancelled_by UUID) CASCADE;

SELECT 'All cancel functions dropped' as status;

-- ============================================================================
-- STEP 3: Verify they are gone
-- ============================================================================

SELECT '=== STEP 3: Verify all cancel functions are dropped ===' as step;

SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ All cancel functions dropped successfully'
    ELSE '❌ Some functions still exist: ' || STRING_AGG(proname, ', ')
  END as verification_result
FROM pg_proc
WHERE proname LIKE 'cancel_session%'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 4: Create cancel_session_with_reason (VOLATILE)
-- ============================================================================

SELECT '=== STEP 4: Creating cancel_session_with_reason ===' as step;

CREATE FUNCTION cancel_session_with_reason(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_session RECORD;
BEGIN
  -- Get session details
  SELECT
    s.id,
    s.client_id,
    s.trainer_id,
    s.scheduled_start,
    s.scheduled_end,
    s.status,
    s.package_id
  INTO v_session
  FROM sessions s
  WHERE s.id = p_session_id
    AND s.status IN ('scheduled', 'confirmed');

  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or cannot be cancelled'
    );
  END IF;

  -- Update session status to cancelled
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = p_cancellation_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = NOW()
  WHERE id = p_session_id;

  -- If session was linked to a package, refund the session
  IF v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      used_sessions = GREATEST(0, used_sessions - 1),
      remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
    WHERE id = v_session.package_id;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Session cancelled successfully',
    'session_id', p_session_id,
    'refunded', v_session.package_id IS NOT NULL
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$;

-- ============================================================================
-- STEP 5: Create cancel_session_with_refund (VOLATILE)
-- ============================================================================

SELECT '=== STEP 5: Creating cancel_session_with_refund ===' as step;

CREATE FUNCTION cancel_session_with_refund(
  p_session_id UUID,
  p_cancelled_by UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_session RECORD;
BEGIN
  -- Get session details
  SELECT
    s.id,
    s.client_id,
    s.trainer_id,
    s.scheduled_start,
    s.status,
    s.package_id
  INTO v_session
  FROM sessions s
  WHERE s.id = p_session_id
    AND s.status IN ('scheduled', 'confirmed');

  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or cannot be cancelled'
    );
  END IF;

  -- Cancel the session
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = COALESCE(p_reason, 'Cancelled by user'),
    cancelled_by = p_cancelled_by,
    cancelled_at = NOW()
  WHERE id = p_session_id;

  -- Refund to package if linked
  IF v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      used_sessions = GREATEST(0, used_sessions - 1),
      remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
    WHERE id = v_session.package_id;
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Session cancelled and refunded',
    'session_id', p_session_id
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$;

-- ============================================================================
-- STEP 6: Grant permissions
-- ============================================================================

SELECT '=== STEP 6: Granting permissions ===' as step;

GRANT EXECUTE ON FUNCTION cancel_session_with_reason(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_refund(UUID, UUID, TEXT) TO authenticated;

-- ============================================================================
-- STEP 7: Final verification
-- ============================================================================

SELECT '=== STEP 7: Final verification ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  CASE provolatile
    WHEN 'v' THEN '✅ VOLATILE'
    ELSE '❌ NOT VOLATILE'
  END as volatility
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

SELECT '=== ✅ DONE: Functions recreated with VOLATILE ===' as final_message;
