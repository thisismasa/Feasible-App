-- ============================================================================
-- CHECK: The WHERE clause in cancel_session_with_reason
-- ============================================================================
-- This checks if the function still has ANY(ARRAY[...]) syntax

SELECT '=== Checking cancel_session_with_reason WHERE clause ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%WHERE s.id = p_session_id%AND s.status = ANY(ARRAY%'
    THEN '❌ BROKEN - Still has ANY(ARRAY[...]) syntax!'
    WHEN prosrc LIKE '%WHERE s.id = p_session_id%AND s.status IN (%scheduled%, %confirmed%)%'
    THEN '✅ FIXED - Uses IN clause'
    WHEN prosrc LIKE '%status IN (%'
    THEN '✅ FIXED - Uses IN clause'
    ELSE '⚠️ CANNOT DETECT - Need manual check'
  END as where_clause_status,
  CASE
    WHEN prosrc LIKE '%ANY(%' THEN '❌ YES - Found ANY'
    ELSE '✅ NO - No ANY found'
  END as has_any_operator
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- Show just the SELECT part (where the error occurs)
-- ============================================================================

SELECT '=== Extract SELECT statement from function ===' as step;

SELECT
  proname as function_name,
  SUBSTRING(prosrc FROM 'SELECT.*?FROM sessions s.*?WHERE.*?LIMIT 1') as select_statement_snippet
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- Quick test: Try to call the function with a dummy session
-- ============================================================================

SELECT '=== TEST: Try calling cancel_session_with_reason ===' as step;

SELECT
  'If this returns an error about ANY/ALL, the function is BROKEN' as test_note,
  'If this returns "Session not found", the function is FIXED' as expected_result;

-- Get a real session ID to test
WITH test_session AS (
  SELECT id, client_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  LIMIT 1
)
SELECT
  cancel_session_with_reason(
    (SELECT id FROM test_session),
    'TEST CANCEL - DO NOT ACTUALLY CANCEL',
    (SELECT client_id FROM test_session)
  ) as test_result;

-- ============================================================================
-- This test will SHOW the actual error if function is broken
-- ============================================================================
