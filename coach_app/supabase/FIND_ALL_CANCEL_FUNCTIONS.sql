-- ============================================================================
-- FIND: All Versions of Cancel Functions (Different Schemas/Signatures)
-- ============================================================================
-- This checks if there are multiple versions of cancel functions that might
-- be causing the ANY/ALL error

SELECT '=== CHECK 1: All cancel functions in ALL schemas ===' as step;

SELECT
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as parameters,
  pg_get_function_result(p.oid) as return_type,
  p.prosrc as source_code,
  '🔍 Check source for ANY/ALL' as action
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname LIKE '%cancel%session%'
ORDER BY n.nspname, p.proname;

-- ============================================================================
-- CHECK 2: Look for ANY/ALL in source code
-- ============================================================================

SELECT '=== CHECK 2: Which functions still have ANY/ALL syntax? ===' as step;

SELECT
  n.nspname as schema_name,
  p.proname as function_name,
  CASE
    WHEN p.prosrc LIKE '%ANY(ARRAY%' OR p.prosrc LIKE '%ALL(ARRAY%'
    THEN '❌ FOUND ANY/ALL - This is the problem!'
    ELSE '✅ Clean - No ANY/ALL found'
  END as has_any_all_syntax,
  SUBSTRING(
    p.prosrc
    FROM '.{0,50}(ANY|ALL)\(ARRAY.{0,100}'
  ) as problematic_code_snippet
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname LIKE '%cancel%session%'
ORDER BY n.nspname, p.proname;

-- ============================================================================
-- CHECK 3: Test cancel_session_with_reason with EXACT Flutter parameters
-- ============================================================================

SELECT '=== CHECK 3: Test with exact parameters Flutter sends ===' as step;

-- Get a real session ID that exists
WITH test_session AS (
  SELECT id as session_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  ORDER BY scheduled_start DESC
  LIMIT 1
)
SELECT
  'Testing cancel_session_with_reason...' as test_description,
  cancel_session_with_reason(
    (SELECT session_id FROM test_session),
    'Cancelled by trainer',  -- This is what Flutter sends
    '00000000-0000-0000-0000-000000000000'::uuid  -- Dummy user ID
  ) as result;

-- ============================================================================
-- CHECK 4: Look for cancel_session_with_refund (might be the actual function)
-- ============================================================================

SELECT '=== CHECK 4: Check cancel_session_with_refund ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  CASE
    WHEN prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%'
    THEN '❌ FOUND ANY/ALL'
    ELSE '✅ Clean'
  END as has_any_all,
  SUBSTRING(
    prosrc
    FROM '.{0,50}(ANY|ALL)\(ARRAY.{0,100}'
  ) as problematic_snippet
FROM pg_proc
WHERE proname = 'cancel_session_with_refund'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- CHECK 5: Show EXACT WHERE clause from cancel functions
-- ============================================================================

SELECT '=== CHECK 5: Extract WHERE clauses from cancel functions ===' as step;

SELECT
  proname as function_name,
  SUBSTRING(
    prosrc
    FROM 'WHERE[^;]*status[^;]*'
  ) as where_clause_with_status
FROM pg_proc
WHERE proname IN ('cancel_session_with_reason', 'cancel_session_with_refund')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- EXPECTED FINDINGS:
-- ============================================================================
-- If error persists, one of these should be true:
-- 1. Multiple versions of function exist (different schemas)
-- 2. Function has ANY/ALL syntax that wasn't fixed
-- 3. cancel_session_with_refund (not cancel_session_with_reason) has the error
-- 4. There's a different function being called that we haven't checked
-- ============================================================================
