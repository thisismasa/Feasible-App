-- ============================================================================
-- DEEP INVESTIGATION: Find the REAL source of ANY/ALL error
-- ============================================================================
-- RLS is disabled everywhere, so the error must come from:
-- 1. A VIEW with ANY/ALL
-- 2. The function itself has ANY/ALL in WHERE clauses
-- 3. PostgREST is misinterpreting the function call

-- ============================================================================
-- PART 1: Show COMPLETE source of cancel_session_v4
-- ============================================================================

SELECT '=== PART 1: Complete function source ===' as step;

SELECT pg_get_functiondef(p.oid) as function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'cancel_session_v4';

-- ============================================================================
-- PART 2: Check ALL views for ANY/ALL syntax
-- ============================================================================

SELECT '=== PART 2: Views with ANY/ALL ===' as step;

SELECT
  table_name as view_name,
  '❌ HAS ANY/ALL' as warning
FROM information_schema.views
WHERE table_schema = 'public'
  AND (
    view_definition LIKE '%ANY%(%'
    OR view_definition LIKE '%ALL%(%'
  )
ORDER BY table_name;

-- ============================================================================
-- PART 3: Check trainer_upcoming_sessions view specifically
-- ============================================================================

SELECT '=== PART 3: trainer_upcoming_sessions view ===' as step;

SELECT view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'trainer_upcoming_sessions';

-- ============================================================================
-- PART 4: Test calling the function DIRECTLY in SQL (bypass PostgREST)
-- ============================================================================

SELECT '=== PART 4: Test function directly in SQL ===' as step;

DO $$
DECLARE
  v_session_id UUID;
  v_trainer_id UUID;
  v_result JSON;
BEGIN
  -- Get a session
  SELECT id, trainer_id
  INTO v_session_id, v_trainer_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  LIMIT 1;

  IF v_session_id IS NULL THEN
    RAISE NOTICE 'No sessions to test';
    RETURN;
  END IF;

  RAISE NOTICE 'Testing direct function call...';

  -- Call function directly (not through PostgREST)
  v_result := cancel_session_v4(
    v_session_id,
    'Direct SQL test',
    v_trainer_id,
    false
  );

  RAISE NOTICE 'Result: %', v_result;
  RAISE NOTICE '✅ Direct SQL call WORKS - error is from PostgREST/Flutter!';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Direct SQL call FAILED: %', SQLERRM;
END $$;

-- ============================================================================
-- This will tell us if the function itself works, or if PostgREST is the issue
-- ============================================================================
