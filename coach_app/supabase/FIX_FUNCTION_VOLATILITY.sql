-- ============================================================================
-- FIX: Force Supabase to refresh function definition by setting VOLATILE
-- ============================================================================
-- The issue might be that PostgREST is caching the function schema.
-- Setting VOLATILE forces it to recalculate every time.

SELECT '=== STEP 1: Check current function volatility ===' as step;

SELECT
  proname as function_name,
  CASE provolatile
    WHEN 'i' THEN 'IMMUTABLE (never changes)'
    WHEN 's' THEN 'STABLE (same within query)'
    WHEN 'v' THEN 'VOLATILE (can change)'
  END as volatility,
  '⚠️ Should be VOLATILE for session operations' as note
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund', 'book_session_with_validation')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- STEP 2: Force functions to be VOLATILE (required for database state changes)
-- ============================================================================

SELECT '=== STEP 2: Setting all session functions to VOLATILE ===' as step;

-- Drop and recreate cancel_session_with_reason with VOLATILE
DROP FUNCTION IF EXISTS cancel_session_with_reason(UUID, TEXT, UUID);

CREATE OR REPLACE FUNCTION cancel_session_with_reason(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE  -- ⚠️ IMPORTANT: Forces fresh execution, no caching
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
    AND s.status IN ('scheduled', 'confirmed');  -- FIXED: Changed from ANY(ARRAY[...])

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
-- STEP 3: Also fix cancel_session_with_refund to be VOLATILE
-- ============================================================================

SELECT '=== STEP 3: Setting cancel_session_with_refund to VOLATILE ===' as step;

DROP FUNCTION IF EXISTS cancel_session_with_refund(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION cancel_session_with_refund(
  p_session_id UUID,
  p_cancelled_by UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE  -- ⚠️ IMPORTANT: Forces fresh execution
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
    AND s.status IN ('scheduled', 'confirmed');  -- FIXED: Changed from ANY(ARRAY[...])

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
-- STEP 4: Grant permissions
-- ============================================================================

SELECT '=== STEP 4: Granting permissions ===' as step;

GRANT EXECUTE ON FUNCTION cancel_session_with_reason TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session_with_refund TO authenticated;

-- ============================================================================
-- STEP 5: Verify volatility is now set
-- ============================================================================

SELECT '=== STEP 5: Verify functions are now VOLATILE ===' as step;

SELECT
  proname as function_name,
  CASE provolatile
    WHEN 'v' THEN '✅ VOLATILE - Will not be cached'
    ELSE '❌ NOT VOLATILE - Problem!'
  END as volatility_status
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- Both functions should show: ✅ VOLATILE - Will not be cached
-- This forces Supabase PostgREST to use the fresh function definition
-- ============================================================================

SELECT '=== ✅ COMPLETE: Functions recreated with VOLATILE ===' as final_message;
SELECT 'Now restart Flutter and the ANY/ALL error should be gone!' as next_step;
