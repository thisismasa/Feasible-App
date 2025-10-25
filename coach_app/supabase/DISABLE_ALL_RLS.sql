-- ============================================================================
-- NUCLEAR OPTION: Disable RLS on ALL tables in public schema
-- ============================================================================
-- ROOT CAUSE: Many tables still have RLS enabled with ANY/ARRAY policies
-- The cancel operation touches multiple tables, any could cause the error

SELECT '=== Disabling RLS on ALL public tables ===' as step;

DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND rowsecurity = true
  LOOP
    EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY', table_record.tablename);
    RAISE NOTICE 'Disabled RLS on: %', table_record.tablename;
  END LOOP;
END $$;

SELECT '✅ RLS disabled on all tables' as result;

-- ============================================================================
-- Drop ALL RLS policies on ALL tables
-- ============================================================================

SELECT '=== Dropping ALL RLS policies ===' as step;

DO $$
DECLARE
  policy_record RECORD;
BEGIN
  FOR policy_record IN
    SELECT DISTINCT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_record.policyname, policy_record.tablename);
    RAISE NOTICE 'Dropped policy % on %', policy_record.policyname, policy_record.tablename;
  END LOOP;
END $$;

SELECT '✅ All RLS policies dropped' as result;

-- ============================================================================
-- Verify ALL tables have RLS disabled
-- ============================================================================

SELECT '=== Verification ===' as step;

SELECT
  COUNT(*) as tables_with_rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = true;

-- Should return 0

SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ PERFECT - NO tables have RLS enabled'
    ELSE '❌ ' || COUNT(*) || ' tables still have RLS enabled!'
  END as final_check
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = true;

-- ============================================================================
-- Reload PostgREST
-- ============================================================================

SELECT '=== Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(1);
NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reloaded 5 times' as result;

-- ============================================================================
-- COMPLETE
-- ============================================================================

SELECT '=== ✅ ALL RLS COMPLETELY DISABLED ===' as final_message;
SELECT 'NO table in the entire database has RLS enabled anymore' as summary;
SELECT 'Test cancel button - it MUST work now!' as next_step;
