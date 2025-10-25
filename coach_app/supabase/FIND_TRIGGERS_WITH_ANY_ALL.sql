-- ============================================================================
-- FIND: All triggers that might have ANY/ALL syntax
-- ============================================================================

SELECT '=== PART 1: All triggers on sessions table ===' as step;

SELECT
  trigger_name,
  event_manipulation as event,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'sessions'
ORDER BY trigger_name;

-- ============================================================================
-- PART 2: All triggers on client_packages table
-- ============================================================================

SELECT '=== PART 2: All triggers on client_packages table ===' as step;

SELECT
  trigger_name,
  event_manipulation as event,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'client_packages'
ORDER BY trigger_name;

-- ============================================================================
-- PART 3: Search ALL triggers for ANY/ALL syntax
-- ============================================================================

SELECT '=== PART 3: Triggers with ANY/ALL syntax ===' as step;

SELECT
  event_object_table as table_name,
  trigger_name,
  '❌ HAS ANY/ALL' as warning,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND (
    action_statement LIKE '%ANY%(%'
    OR action_statement LIKE '%ALL%(%'
  )
ORDER BY event_object_table, trigger_name;

-- ============================================================================
-- PART 4: Get the function definitions for trigger functions
-- ============================================================================

SELECT '=== PART 4: Trigger function sources ===' as step;

SELECT
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname LIKE '%trigger%'
  AND pg_get_functiondef(p.oid) LIKE '%ANY%';

-- ============================================================================
-- PART 5: List ALL triggers in the database
-- ============================================================================

SELECT '=== PART 5: ALL triggers ===' as step;

SELECT DISTINCT
  event_object_table,
  COUNT(*) as trigger_count
FROM information_schema.triggers
WHERE event_object_schema = 'public'
GROUP BY event_object_table
ORDER BY event_object_table;
