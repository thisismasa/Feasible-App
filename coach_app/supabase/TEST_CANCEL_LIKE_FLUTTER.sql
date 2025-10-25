-- ============================================================================
-- TEST: Call cancel_session_with_reason EXACTLY as Flutter does
-- ============================================================================
-- This replicates the exact Flutter RPC call to reproduce the error

SELECT '=== Get a real session to test with ===' as step;

-- Find a session we can use for testing
SELECT
  id as session_id,
  client_id,
  trainer_id,
  scheduled_start,
  status,
  '👆 We will try to cancel this session' as note
FROM sessions
WHERE status IN ('scheduled', 'confirmed')
ORDER BY scheduled_start DESC
LIMIT 1;

-- ============================================================================
-- Call the function EXACTLY as Flutter does
-- ============================================================================

SELECT '=== Calling cancel_session_with_reason (as Flutter does) ===' as step;

-- This is the EXACT call Flutter makes at real_supabase_service.dart:990
-- params: {
--   'p_session_id': sessionId,
--   'p_cancellation_reason': reason,
--   'p_cancelled_by': userId,
-- }

DO $$
DECLARE
  v_test_session_id UUID;
  v_test_user_id UUID;
  v_result JSON;
BEGIN
  -- Get a real session ID
  SELECT id INTO v_test_session_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  ORDER BY scheduled_start DESC
  LIMIT 1;

  -- Get a real user ID (any user)
  SELECT id INTO v_test_user_id
  FROM users
  LIMIT 1;

  -- Call the function exactly as Flutter does
  RAISE NOTICE '📞 Calling cancel_session_with_reason...';
  RAISE NOTICE '   Session ID: %', v_test_session_id;
  RAISE NOTICE '   User ID: %', v_test_user_id;

  v_result := cancel_session_with_reason(
    v_test_session_id,
    'Cancelled by trainer',
    v_test_user_id
  );

  RAISE NOTICE '✅ Result: %', v_result;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
    RAISE NOTICE '❌ DETAIL: %', SQLSTATE;
    -- Don't rethrow - we want to see the error but not fail the script
END;
$$;

-- ============================================================================
-- Alternative: Use SELECT to test (shows result in output)
-- ============================================================================

SELECT '=== Alternative test with SELECT ===' as step;

WITH test_data AS (
  SELECT
    s.id as session_id,
    (SELECT id FROM users LIMIT 1) as user_id
  FROM sessions s
  WHERE s.status IN ('scheduled', 'confirmed')
  ORDER BY s.scheduled_start DESC
  LIMIT 1
)
SELECT
  'Test result:' as description,
  cancel_session_with_reason(
    (SELECT session_id FROM test_data),
    'Cancelled by trainer',
    (SELECT user_id FROM test_data)
  ) as function_result;

-- ============================================================================
-- EXPECTED OUTCOME:
-- ============================================================================
-- If database is correct:
--   Should return: {"success": false, "error": "..."} or {"success": true}
--   WITHOUT showing ANY/ALL error
--
-- If database has hidden error:
--   Should show: ERROR: op ANY/ALL (array) requires operator to yield boolean
--
-- This will prove whether error is in database or in Flutter/Supabase client
-- ============================================================================
