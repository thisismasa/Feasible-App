-- ============================================================================
-- CHECK: What cancel session functions exist and their definitions
-- ============================================================================

-- Check if cancel functions exist
SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prokind as function_type
FROM pg_proc
WHERE proname LIKE '%cancel%'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- Get full definition of cancel_session_with_refund if it exists
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'cancel_session_with_refund'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Get full definition of cancel_session_with_reason if it exists
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- WHAT TO DO:
-- ============================================================================
-- 1. Run this to see what cancel functions exist
-- 2. One of them has a SQL error: "op ANY/ALL (array) requires operator to yield boolean"
-- 3. This usually means something like: WHERE status = ANY(ARRAY['value1', 'value2'])
--    should be: WHERE status IN ('value1', 'value2')
-- 4. Need to fix the function definition
-- ============================================================================
