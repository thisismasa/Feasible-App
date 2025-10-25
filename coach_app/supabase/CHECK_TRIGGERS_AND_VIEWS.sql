-- ============================================================================
-- CHECK: Triggers, Views, and Policies that might have ANY/ALL errors
-- ============================================================================
-- The error might be coming from a trigger or row-level security policy!

SELECT '=== CHECK 1: All triggers on sessions table ===' as step;

SELECT
  tgname as trigger_name,
  tgtype as trigger_type,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as trigger_definition,
  '🔍 Check if this trigger has ANY/ALL' as note
FROM pg_trigger
WHERE tgrelid = 'sessions'::regclass
  AND tgname NOT LIKE 'pg_%'  -- Exclude system triggers
ORDER BY tgname;

-- ============================================================================
-- CHECK 2: Row Level Security Policies on sessions table
-- ============================================================================

SELECT '=== CHECK 2: RLS Policies on sessions table ===' as step;

SELECT
  schemaname,
  tablename,
  policyname as policy_name,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression,
  '⚠️ Check for ANY/ALL in qual or with_check' as note
FROM pg_policies
WHERE tablename = 'sessions'
ORDER BY policyname;

-- ============================================================================
-- CHECK 3: Check if ANY policies have ANY/ALL syntax
-- ============================================================================

SELECT '=== CHECK 3: Search for ANY/ALL in policy definitions ===' as step;

SELECT
  tablename,
  policyname,
  '❌ FOUND ANY/ALL IN POLICY!' as issue,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
    OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%')
ORDER BY tablename, policyname;

-- ============================================================================
-- CHECK 4: Views that involve sessions
-- ============================================================================

SELECT '=== CHECK 4: Views involving sessions ===' as step;

SELECT
  schemaname,
  viewname,
  definition,
  '🔍 Check for ANY/ALL in view definition' as note
FROM pg_views
WHERE schemaname = 'public'
  AND (viewname LIKE '%session%' OR definition LIKE '%sessions%')
ORDER BY viewname;

-- ============================================================================
-- CHECK 5: Check client_packages table policies
-- ============================================================================

SELECT '=== CHECK 5: RLS Policies on client_packages ===' as step;

SELECT
  policyname as policy_name,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression,
  '⚠️ Policies on client_packages might affect cancel' as note
FROM pg_policies
WHERE tablename = 'client_packages'
ORDER BY policyname;

-- ============================================================================
-- CHECK 6: Find ALL ANY/ALL usage across ALL database objects
-- ============================================================================

SELECT '=== CHECK 6: ALL ANY/ALL usage in database ===' as step;

-- Check functions
SELECT
  'function' as object_type,
  proname as object_name,
  '❌ Function has ANY/ALL' as issue,
  SUBSTRING(prosrc FROM '.{0,100}(ANY|ALL)\(ARRAY.{0,100}') as snippet
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND (prosrc LIKE '%ANY(ARRAY%' OR prosrc LIKE '%ALL(ARRAY%')

UNION ALL

-- Check policies
SELECT
  'policy' as object_type,
  tablename || '.' || policyname as object_name,
  '❌ Policy has ANY/ALL' as issue,
  COALESCE(qual, with_check) as snippet
FROM pg_policies
WHERE (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
    OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%')

UNION ALL

-- Check views
SELECT
  'view' as object_type,
  viewname as object_name,
  '❌ View has ANY/ALL' as issue,
  SUBSTRING(definition FROM '.{0,100}(ANY|ALL)\(ARRAY.{0,100}') as snippet
FROM pg_views
WHERE schemaname = 'public'
  AND (definition LIKE '%ANY(ARRAY%' OR definition LIKE '%ALL(ARRAY%')

ORDER BY object_type, object_name;

-- ============================================================================
-- EXPECTED FINDINGS:
-- ============================================================================
-- If this shows NO results in CHECK 6, then the database is truly clean.
-- If Flutter still shows error, then it must be:
-- 1. Supabase client cached schema
-- 2. Wrong Supabase project URL
-- 3. Flutter using old .env file with different database
-- ============================================================================
