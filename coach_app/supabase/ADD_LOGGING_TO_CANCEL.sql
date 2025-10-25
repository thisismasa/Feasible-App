-- ============================================================================
-- ADD LOGGING: Update cancel_session_with_reason to show detailed logs
-- ============================================================================

DROP FUNCTION IF EXISTS cancel_session_with_reason(UUID, TEXT, UUID) CASCADE;

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
  -- Log start
  RAISE NOTICE '========================================';
  RAISE NOTICE '🔴 CANCEL SESSION CALLED';
  RAISE NOTICE 'Session ID: %', p_session_id;
  RAISE NOTICE 'Reason: %', p_cancellation_reason;
  RAISE NOTICE 'Cancelled by: %', p_cancelled_by;
  RAISE NOTICE '========================================';

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
  RAISE NOTICE '   Scheduled: % to %', v_session.scheduled_start, v_session.scheduled_end;

  -- Update session status to cancelled
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = p_cancellation_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = NOW()
  WHERE id = p_session_id;

  RAISE NOTICE '✅ Session status updated to CANCELLED';

  -- If session was linked to a package, refund the session
  IF v_session.package_id IS NOT NULL THEN
    RAISE NOTICE '💰 Refunding session to package: %', v_session.package_id;

    UPDATE client_packages
    SET
      used_sessions = GREATEST(0, used_sessions - 1),
      remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
    WHERE id = v_session.package_id;

    RAISE NOTICE '✅ Package refunded: -1 used_sessions, +1 remaining_sessions';
  ELSE
    RAISE NOTICE '⚠️  No package linked - no refund needed';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ CANCEL SESSION COMPLETED SUCCESSFULLY';
  RAISE NOTICE '========================================';

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Session cancelled successfully',
    'session_id', p_session_id,
    'refunded', v_session.package_id IS NOT NULL
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '========================================';
    RAISE NOTICE '❌ ERROR OCCURRED: %', SQLERRM;
    RAISE NOTICE '========================================';
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION cancel_session_with_reason(UUID, TEXT, UUID) TO authenticated;

-- Verification
SELECT '=== ✅ Logging added to cancel_session_with_reason ===' as result;
SELECT 'Now when you cancel a session, you will see detailed logs in terminal!' as note;
