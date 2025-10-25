-- ============================================================================
-- COMPREHENSIVE SEARCH: Find ANY/ALL syntax in ALL database objects
-- ============================================================================
-- This will show the ACTUAL source code where ANY/ALL appears

-- ============================================================================
-- PART 1: Search in ALL FUNCTIONS (including cancel_session_v3)
-- ============================================================================

SELECT
  '🔍 FUNCTION: ' || routine_name as object_name,
  routine_definition as source_code
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND (
    routine_definition ILIKE '%ANY%(%'
    OR routine_definition ILIKE '%ALL%(%'
  )
ORDER BY routine_name;

-- ============================================================================
-- PART 2: Search in ALL RLS POLICIES
-- ============================================================================

SELECT
  '🔍 RLS POLICY: ' || policyname as object_name,
  'Table: ' || tablename as target,
  'Command: ' || cmd as command_type,
  'USING: ' || COALESCE(qual, 'none') as using_clause,
  'WITH CHECK: ' || COALESCE(with_check, 'none') as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND (
    qual ILIKE '%ANY%(%'
    OR qual ILIKE '%ALL%(%'
    OR with_check ILIKE '%ANY%(%'
    OR with_check ILIKE '%ALL%(%'
  )
ORDER BY tablename, policyname;

-- ============================================================================
-- PART 3: Search in ALL VIEWS
-- ============================================================================

SELECT
  '🔍 VIEW: ' || table_name as object_name,
  view_definition as source_code
FROM information_schema.views
WHERE table_schema = 'public'
  AND (
    view_definition ILIKE '%ANY%(%'
    OR view_definition ILIKE '%ALL%(%'
  )
ORDER BY table_name;

-- ============================================================================
-- PART 4: Search in ALL TRIGGERS
-- ============================================================================

SELECT
  '🔍 TRIGGER: ' || trigger_name as object_name,
  'On table: ' || event_object_table as target,
  action_statement as source_code
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND (
    action_statement ILIKE '%ANY%(%'
    OR action_statement ILIKE '%ALL%(%'
  )
ORDER BY event_object_table, trigger_name;

-- ============================================================================
-- PART 5: Check ALL RLS policies on client_packages table too
-- ============================================================================

SELECT
  '🔍 RLS POLICY ON client_packages: ' || policyname as object_name,
  'USING: ' || COALESCE(qual, 'none') as using_clause,
  'WITH CHECK: ' || COALESCE(with_check, 'none') as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'client_packages'
  AND (
    qual ILIKE '%ANY%(%'
    OR qual ILIKE '%ALL%(%'
    OR with_check ILIKE '%ANY%(%'
    OR with_check ILIKE '%ALL%(%'
  );

-- ============================================================================
-- PART 6: Show full source of cancel_session_v3 function
-- ============================================================================

SELECT
  '🔍 FULL SOURCE of cancel_session_v3:' as info,
  pg_get_functiondef(p.oid) as full_function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'cancel_session_v3';

-- ============================================================================
-- DONE - Review all results above
-- ============================================================================
