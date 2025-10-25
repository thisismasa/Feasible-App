-- ============================================================================
-- VERIFY: Check if cancel function fix was applied
-- ============================================================================

-- Check return type of cancel functions
SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prorettype::regtype as return_type,
  CASE
    WHEN prorettype::regtype::text = 'json' THEN '✅ Correct (V2 applied)'
    ELSE '❌ Wrong type - need to re-run V2'
  END as status
FROM pg_proc
WHERE proname IN ('cancel_session_with_refund', 'cancel_session_with_reason')
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- Get function definitions to check for ANY/ALL syntax
SELECT
  proname as function_name,
  pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'cancel_session_with_refund'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- WHAT TO LOOK FOR:
-- ============================================================================
-- If definition contains "= ANY(ARRAY[" → V2 NOT applied, run FIX_CANCEL_FUNCTIONS_V2.sql
-- If definition contains "IN (" → V2 IS applied, error is from elsewhere
-- ============================================================================
