-- ============================================================================
-- COMPREHENSIVE SEARCH: Find ANY/ALL EVERYWHERE in database
-- ============================================================================
-- This will search EVERY possible location for ANY/ALL syntax

-- ============================================================================
-- PART 1: Search ALL Functions
-- ============================================================================

SELECT '=== PART 1: Functions with ANY/ALL ===' as search_section;

SELECT
  'FUNCTION' as object_type,
  n.nspname as schema_name,
  p.proname as object_name,
  pg_get_function_arguments(p.oid) as parameters,
  '❌ FOUND ANY/ALL' as status,
  SUBSTRING(p.prosrc FROM '(.{0,100}(ANY|ALL)\(ARRAY.{0,200})') as code_snippet,
  LENGTH(p.prosrc) as function_length
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND (p.prosrc LIKE '%ANY(ARRAY%' OR p.prosrc LIKE '%ALL(ARRAY%')
ORDER BY p.proname;

-- ============================================================================
-- PART 2: Search ALL RLS Policies
-- ============================================================================

SELECT '=== PART 2: RLS Policies with ANY/ALL ===' as search_section;

SELECT
  'POLICY' as object_type,
  schemaname,
  tablename,
  policyname as object_name,
  '❌ FOUND ANY/ALL' as status,
  COALESCE(
    SUBSTRING(qual FROM '(.{0,100}(ANY|ALL)\(ARRAY.{0,100})'),
    SUBSTRING(with_check FROM '(.{0,100}(ANY|ALL)\(ARRAY.{0,100})')
  ) as code_snippet,
  qual as using_clause,
  with_check as check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
    OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%')
ORDER BY tablename, policyname;

-- ============================================================================
-- PART 3: Search ALL Views
-- ============================================================================

SELECT '=== PART 3: Views with ANY/ALL ===' as search_section;

SELECT
  'VIEW' as object_type,
  schemaname,
  viewname as object_name,
  '❌ FOUND ANY/ALL' as status,
  SUBSTRING(definition FROM '(.{0,100}(ANY|ALL)\(ARRAY.{0,200})') as code_snippet
FROM pg_views
WHERE schemaname = 'public'
  AND (definition LIKE '%ANY(ARRAY%' OR definition LIKE '%ALL(ARRAY%')
ORDER BY viewname;

-- ============================================================================
-- PART 4: Search ALL Triggers
-- ============================================================================

SELECT '=== PART 4: Triggers with ANY/ALL ===' as search_section;

SELECT
  'TRIGGER' as object_type,
  tgrelid::regclass::text as table_name,
  tgname as object_name,
  pg_get_triggerdef(oid) as trigger_definition,
  CASE
    WHEN pg_get_triggerdef(oid) LIKE '%ANY(ARRAY%' OR pg_get_triggerdef(oid) LIKE '%ALL(ARRAY%'
    THEN '❌ FOUND ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_trigger
WHERE tgrelid IN (
    SELECT oid FROM pg_class WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  )
  AND tgname NOT LIKE 'pg_%'
  AND (pg_get_triggerdef(oid) LIKE '%ANY(ARRAY%' OR pg_get_triggerdef(oid) LIKE '%ALL(ARRAY%')
ORDER BY tgrelid::regclass::text, tgname;

-- ============================================================================
-- PART 5: Check sessions table specifically
-- ============================================================================

SELECT '=== PART 5: Sessions table analysis ===' as search_section;

-- Check all constraints on sessions table
SELECT
  'CONSTRAINT' as object_type,
  conname as object_name,
  pg_get_constraintdef(oid) as definition,
  CASE
    WHEN pg_get_constraintdef(oid) LIKE '%ANY(ARRAY%' OR pg_get_constraintdef(oid) LIKE '%ALL(ARRAY%'
    THEN '❌ FOUND ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_constraint
WHERE conrelid = 'sessions'::regclass
ORDER BY conname;

-- ============================================================================
-- PART 6: SUMMARY - What has ANY/ALL?
-- ============================================================================

SELECT '=== PART 6: SUMMARY ===' as search_section;

WITH all_any_all AS (
  -- Functions
  SELECT 'Functions' as category, COUNT(*) as count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND (p.prosrc LIKE '%ANY(ARRAY%' OR p.prosrc LIKE '%ALL(ARRAY%')

  UNION ALL

  -- Policies
  SELECT 'Policies' as category, COUNT(*) as count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND (qual LIKE '%ANY(ARRAY%' OR qual LIKE '%ALL(ARRAY%'
      OR with_check LIKE '%ANY(ARRAY%' OR with_check LIKE '%ALL(ARRAY%')

  UNION ALL

  -- Views
  SELECT 'Views' as category, COUNT(*) as count
  FROM pg_views
  WHERE schemaname = 'public'
    AND (definition LIKE '%ANY(ARRAY%' OR definition LIKE '%ALL(ARRAY%')
)
SELECT
  category,
  count,
  CASE
    WHEN count > 0 THEN '❌ FOUND ' || count || ' objects with ANY/ALL!'
    ELSE '✅ Clean'
  END as status
FROM all_any_all
ORDER BY count DESC;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- This will show EVERY object in the database that has ANY/ALL syntax
-- The root cause MUST be in one of these results!
-- ============================================================================

SELECT '=== 🔍 SEARCH COMPLETE ===' as final_message;
