-- ============================================================================
-- SHOW: Complete source code of cancel_session_v4
-- ============================================================================

SELECT pg_get_functiondef(p.oid) as function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'cancel_session_v4';

-- ============================================================================
-- Also check which tables have RLS enabled
-- ============================================================================

SELECT
  tablename,
  rowsecurity as rls_enabled,
  CASE
    WHEN rowsecurity = true THEN '⚠️ RLS ENABLED - Could cause ANY/ALL error'
    ELSE '✅ RLS Disabled'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
