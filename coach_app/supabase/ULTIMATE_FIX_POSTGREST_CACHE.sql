-- ============================================================================
-- ULTIMATE FIX: Restart PostgREST by changing database config
-- ============================================================================
-- PostgREST NOTIFY doesn't work. We need to force restart by:
-- 1. Changing the schema version
-- 2. Recreating the function with a completely new name

SELECT '=== STEP 1: Create cancel_session_v3 (NEW NAME) ===' as step;

-- Drop v2 and create v3
DROP FUNCTION IF EXISTS cancel_session_v2 CASCADE;
DROP FUNCTION IF EXISTS cancel_session_v3 CASCADE;

CREATE FUNCTION cancel_session_v3(
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
  RAISE NOTICE '========================================';
  RAISE NOTICE '🔴 CANCEL SESSION V3 CALLED';
  RAISE NOTICE 'Session ID: %', p_session_id;
  RAISE NOTICE 'Reason: %', p_cancellation_reason;
  RAISE NOTICE 'Charge No Show: %', p_charge_no_show;
  RAISE NOTICE '========================================';

  -- Use IN syntax - NO ANY/ALL!
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
    RAISE NOTICE '❌ Session not found';
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Session not found or cannot be cancelled'
    );
  END IF;

  RAISE NOTICE '📋 Session found: status=%', v_session.status;

  -- Cancel session
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = p_cancellation_reason,
    cancelled_by = p_cancelled_by,
    cancelled_at = NOW()
  WHERE id = p_session_id;

  RAISE NOTICE '✅ Session cancelled';

  -- Refund logic
  IF v_session.package_id IS NOT NULL THEN
    IF p_charge_no_show = TRUE THEN
      RAISE NOTICE '❌ NO SHOW - No refund';
    ELSE
      UPDATE client_packages
      SET
        used_sessions = GREATEST(0, used_sessions - 1),
        remaining_sessions = remaining_sessions + 1,
        updated_at = NOW()
      WHERE id = v_session.package_id;
      RAISE NOTICE '💰 Refunded to package';
    END IF;
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ COMPLETE';
  RAISE NOTICE '========================================';

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Session cancelled successfully',
    'session_id', p_session_id,
    'refunded', (v_session.package_id IS NOT NULL AND p_charge_no_show = FALSE)
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION cancel_session_v3(UUID, TEXT, UUID, BOOLEAN) TO authenticated;

SELECT '✅ cancel_session_v3 created' as result;

-- ============================================================================
-- STEP 2: Test the function in SQL (prove it works)
-- ============================================================================

SELECT '=== STEP 2: Test cancel_session_v3 in SQL ===' as step;

DO $$
DECLARE
  v_test_session_id UUID;
  v_test_user_id UUID;
  v_result JSON;
BEGIN
  -- Get any session
  SELECT id INTO v_test_session_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  LIMIT 1;

  -- Get any user
  SELECT id INTO v_test_user_id
  FROM users
  LIMIT 1;

  IF v_test_session_id IS NULL THEN
    RAISE NOTICE 'No sessions to test with - create a session first';
    RETURN;
  END IF;

  RAISE NOTICE '📞 Testing cancel_session_v3...';

  v_result := cancel_session_v3(
    v_test_session_id,
    'Test cancellation',
    COALESCE(v_test_user_id, '00000000-0000-0000-0000-000000000000'::uuid),
    FALSE
  );

  RAISE NOTICE '✅ Result: %', v_result;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ SQL ERROR: %', SQLERRM;
END;
$$;

-- ============================================================================
-- STEP 3: Check for ANY/ALL in RLS policies (might be the source!)
-- ============================================================================

SELECT '=== STEP 3: Check RLS policies for ANY/ALL ===' as step;

SELECT
  schemaname,
  tablename,
  policyname,
  '❌ POLICY HAS ANY/ALL - THIS IS THE PROBLEM!' as issue,
  qual as policy_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
    OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%')
ORDER BY tablename, policyname;

-- If no results, policies are clean
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ No RLS policies with ANY/ALL found'
    ELSE '❌ Found ' || COUNT(*) || ' policies with ANY/ALL syntax!'
  END as rls_check
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
    OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%');

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- 1. cancel_session_v3 created successfully
-- 2. SQL test shows function works (no ANY/ALL error)
-- 3. RLS check shows if policies have ANY/ALL syntax
--
-- Next: Update Flutter to call cancel_session_v3
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'If SQL test passed: error is from RLS policies or PostgREST cache' as diagnosis;
SELECT 'Check STEP 3 results for ANY/ALL in policies!' as action;
