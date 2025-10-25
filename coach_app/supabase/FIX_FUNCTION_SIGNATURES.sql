-- ============================================================================
-- FIX: Check existing function signatures and drop correctly
-- ============================================================================

SELECT '=== STEP 1: Find ALL cancel_session_with_refund signatures ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  pg_get_function_identity_arguments(oid) as identity_args,
  '👆 Use identity_args for DROP' as note
FROM pg_proc
WHERE proname = 'cancel_session_with_refund'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- STEP 2: Drop ALL versions of cancel_session_with_refund
-- ============================================================================

SELECT '=== STEP 2: Dropping all versions of cancel_session_with_refund ===' as step;

-- Drop with all possible signatures
DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, UUID);

-- ============================================================================
-- STEP 3: Recreate with correct signature and VOLATILE
-- ============================================================================

SELECT '=== STEP 3: Creating cancel_session_with_refund with VOLATILE ===' as step;

CREATE OR REPLACE FUNCTION cancel_session_with_refund(
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
-- STEP 4: Drop and recreate cancel_session_with_reason
-- ============================================================================

SELECT '=== STEP 4: Dropping cancel_session_with_reason ===' as step;

DROP FUNCTION IF EXISTS cancel_session_with_reason(UUID, TEXT, UUID);

SELECT '=== Creating cancel_session_with_reason with VOLATILE ===' as step;

CREATE OR REPLACE FUNCTION cancel_session_with_reason(
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
  v_package_id UUID;
  v_result JSON;
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
-- STEP 5: Grant permissions
-- ============================================================================

SELECT '=== STEP 5: Granting permissions ===' as step;

GRANT EXECUTE ON FUNCTION cancel_session_with_reason TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_refund TO authenticated;

-- ============================================================================
-- STEP 6: Verify both functions are VOLATILE
-- ============================================================================

SELECT '=== STEP 6: Verify functions are VOLATILE ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  CASE provolatile
    WHEN 'v' THEN '✅ VOLATILE - Will not be cached'
    ELSE '❌ NOT VOLATILE'
  END as volatility_status
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- Both functions should show: ✅ VOLATILE - Will not be cached
-- ============================================================================

SELECT '=== ✅ COMPLETE: Functions fixed with VOLATILE ===' as final_message;
SELECT 'Now kill all Flutter processes and restart!' as next_step;
