-- ============================================================================
-- SOLUTION: Create NEW function with different name to bypass PostgREST cache
-- ============================================================================
-- PostgREST is caching the old function schema with ANY/ALL
-- By creating a NEW function name, PostgREST will use fresh schema

SELECT '=== Creating cancel_session_v2 (bypasses cache) ===' as step;

CREATE OR REPLACE FUNCTION cancel_session_v2(
  p_session_id UUID,
  p_cancellation_reason TEXT,
  p_cancelled_by UUID,
  p_charge_no_show BOOLEAN DEFAULT FALSE
)
RETURNS JSON
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_session RECORD;
BEGIN
  -- Log start
  RAISE NOTICE '========================================';
  RAISE NOTICE '🔴 CANCEL SESSION V2 CALLED';
  RAISE NOTICE 'Session ID: %', p_session_id;
  RAISE NOTICE 'Reason: %', p_cancellation_reason;
  RAISE NOTICE 'Cancelled by: %', p_cancelled_by;
  RAISE NOTICE 'Charge No Show: %', p_charge_no_show;
  RAISE NOTICE '========================================';

  -- Get session details using IN syntax (NOT ANY/ALL!)
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
    AND s.status IN ('scheduled', 'confirmed');  -- ✅ CORRECT SYNTAX

  IF NOT FOUND THEN
    RAISE NOTICE '❌ Session not found or already cancelled';
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or cannot be cancelled'
    );
  END IF;

  RAISE NOTICE '📋 Session found:';
  RAISE NOTICE '   Client ID: %', v_session.client_id;
  RAISE NOTICE '   Trainer ID: %', v_session.trainer_id;
  RAISE NOTICE '   Status: %', v_session.status;
  RAISE NOTICE '   Package ID: %', v_session.package_id;

  -- Update session status to cancelled
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = p_cancellation_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = NOW()
  WHERE id = p_session_id;

  RAISE NOTICE '✅ Session status updated to CANCELLED';

  -- BUSINESS LOGIC: Refund or charge based on no-show flag
  IF v_session.package_id IS NOT NULL THEN
    IF p_charge_no_show = TRUE THEN
      -- NO SHOW: Session is cancelled but client is charged (no refund)
      RAISE NOTICE '❌ NO SHOW - Session charged, NO REFUND';
      -- Do nothing - keep used_sessions as is
    ELSE
      -- NORMAL CANCEL: Refund the session to package
      RAISE NOTICE '💰 Normal cancel - Refunding session to package';
      UPDATE client_packages
      SET
        used_sessions = GREATEST(0, used_sessions - 1),
        remaining_sessions = remaining_sessions + 1,
        updated_at = NOW()
      WHERE id = v_session.package_id;

      RAISE NOTICE '✅ Package refunded: -1 used, +1 remaining';
    END IF;
  ELSE
    RAISE NOTICE '⚠️  No package linked';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ CANCEL COMPLETED SUCCESSFULLY';
  RAISE NOTICE '========================================';

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Session cancelled successfully',
    'session_id', p_session_id,
    'refunded', (v_session.package_id IS NOT NULL AND p_charge_no_show = FALSE),
    'charged_no_show', p_charge_no_show
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '========================================';
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
    RAISE NOTICE '========================================';
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION cancel_session_v2(UUID, TEXT, UUID, BOOLEAN) TO authenticated;

-- Verification
SELECT '=== ✅ cancel_session_v2 created successfully ===' as result;
SELECT 'This NEW function will bypass PostgREST cache!' as note;
SELECT 'Next: Update Flutter to call cancel_session_v2 instead of cancel_session_with_reason' as next_step;
