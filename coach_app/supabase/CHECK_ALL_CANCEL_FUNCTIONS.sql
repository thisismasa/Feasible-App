-- ============================================================================
-- CHECK: Find ALL Cancel-Related Functions in Database
-- ============================================================================

SELECT '=== ALL functions with "cancel" in name ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prorettype::regtype as return_type,
  CASE
    WHEN prosrc LIKE '%ANY(ARRAY%' THEN '❌ HAS ANY/ALL ISSUE'
    WHEN prosrc LIKE '%IN (''scheduled'', ''confirmed'')%' THEN '✅ FIXED'
    ELSE '⚠️ UNKNOWN'
  END as syntax_status
FROM pg_proc
WHERE proname LIKE '%cancel%'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- ============================================================================
-- Show the EXACT source code of cancel_session_with_reason
-- ============================================================================

SELECT '=== EXACT source of cancel_session_with_reason ===' as step;

SELECT
  proname as function_name,
  prosrc as source_code
FROM pg_proc
WHERE proname = 'cancel_session_with_reason'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
