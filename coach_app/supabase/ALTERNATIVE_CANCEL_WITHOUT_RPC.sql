-- ============================================================================
-- ALTERNATIVE SOLUTION: Cancel session without using RPC
-- ============================================================================
-- If PostgREST RPC is causing ANY/ALL errors, bypass it entirely
-- Use direct table operations from Flutter instead

-- This is what we'll implement in Flutter:
-- 1. SELECT session from sessions table
-- 2. UPDATE sessions table directly
-- 3. UPDATE client_packages table directly

-- Let's verify this approach works in SQL:

DO $$
DECLARE
  v_session_id UUID;
  v_session RECORD;
  v_trainer_id UUID;
BEGIN
  -- Get a test session
  SELECT id, trainer_id
  INTO v_session_id, v_trainer_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  LIMIT 1;

  IF v_session_id IS NULL THEN
    RAISE NOTICE 'No sessions to test';
    RETURN;
  END IF;

  RAISE NOTICE '=== Testing DIRECT TABLE operations (no RPC) ===';

  -- STEP 1: Get session details (what Flutter will do)
  SELECT
    s.id,
    s.client_id,
    s.trainer_id,
    s.status,
    s.package_id
  INTO v_session
  FROM sessions s
  WHERE s.id = v_session_id
    AND s.status IN ('scheduled', 'confirmed');

  IF NOT FOUND THEN
    RAISE NOTICE '❌ Session not found';
    RETURN;
  END IF;

  RAISE NOTICE '✅ Session found: %', v_session.id;

  -- STEP 2: Update session directly
  UPDATE sessions
  SET
    status = 'cancelled',
    cancellation_reason = 'Direct table update test',
    cancelled_by = v_trainer_id,
    cancelled_at = NOW()
  WHERE id = v_session_id;

  RAISE NOTICE '✅ Session cancelled';

  -- STEP 3: Refund package if needed
  IF v_session.package_id IS NOT NULL THEN
    UPDATE client_packages
    SET
      used_sessions = GREATEST(0, used_sessions - 1),
      remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
    WHERE id = v_session.package_id;

    RAISE NOTICE '✅ Package refunded';
  END IF;

  RAISE NOTICE '✅✅✅ DIRECT TABLE OPERATIONS WORK!';
  RAISE NOTICE 'Solution: Use direct .update() calls in Flutter instead of .rpc()';

END $$;
