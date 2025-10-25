-- ============================================================================
-- TRACE: Follow cancel_session_with_reason to find ANY/ALL error source
-- ============================================================================
-- This will show the COMPLETE source code and check if it calls other functions

SELECT '=== STEP 1: Show FULL source of cancel_session_with_reason ===' as step;

SELECT
  proname as function_name,
  prosrc as full_source_code
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 2: Check if this function CALLS other functions
-- ============================================================================

SELECT '=== STEP 2: Does cancel_session_with_reason call other functions? ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%cancel_session_with_refund%'
    THEN '⚠️ CALLS cancel_session_with_refund'
    ELSE '✅ Does not call other cancel functions'
  END as calls_other_functions,
  CASE
    WHEN prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%'
    THEN '❌ HAS ANY/ALL SYNTAX'
    ELSE '✅ NO ANY/ALL SYNTAX'
  END as has_any_all
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 3: Check cancel_session_with_refund (it might be called internally)
-- ============================================================================

SELECT '=== STEP 3: Check cancel_session_with_refund source ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%'
    THEN '❌ HAS ANY/ALL SYNTAX - THIS IS THE PROBLEM!'
    ELSE '✅ NO ANY/ALL SYNTAX'
  END as has_any_all,
  prosrc as full_source_code
FROM pg_proc
WHERE proname = 'cancel_session_with_refund'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 4: Search for ANY/ALL in ALL related functions
-- ============================================================================

SELECT '=== STEP 4: Find ANY/ALL in any session-related function ===' as step;

SELECT
  proname as function_name,
  '❌ FOUND ANY/ALL' as issue,
  SUBSTRING(
    prosrc
    FROM '.{0,100}(ANY|ALL)\(ARRAY.{0,200}'
  ) as problematic_code
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND (prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%')
  AND proname LIKE '%session%'
ORDER BY proname;

-- ============================================================================
-- STEP 5: Get list of ALL functions that might be involved
-- ============================================================================

SELECT '=== STEP 5: All session/package related functions ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  CASE
    WHEN prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%'
    THEN '❌ HAS ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND (proname LIKE '%session%' OR proname LIKE '%package%')
ORDER BY
  CASE WHEN prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%' THEN 0 ELSE 1 END,
  proname;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- This should show us:
-- 1. The complete source of cancel_session_with_reason
-- 2. If it calls cancel_session_with_refund or other functions
-- 3. If cancel_session_with_refund has ANY/ALL syntax
-- 4. Any other functions that still have ANY/ALL syntax
--
-- The error MUST be coming from one of these places!
-- ============================================================================
