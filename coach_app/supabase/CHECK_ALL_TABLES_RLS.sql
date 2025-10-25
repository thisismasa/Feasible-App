-- ============================================================================
-- CHECK: All tables that cancel_session_v3 touches and their RLS policies
-- ============================================================================

-- Tables involved in cancel operation:
-- 1. sessions - we already fixed
-- 2. client_packages - might have RLS with ANY/ALL
-- 3. users - might be checked during the operation

-- ============================================================================
-- Show ALL RLS policies that contain ANY/ALL on ANY table
-- ============================================================================

SELECT
  'Table: ' || tablename as table_info,
  '  Policy: ' || policyname as policy_info,
  '  Command: ' || cmd as command_type,
  '  ❌ USING: ' || qual as problematic_using
FROM pg_policies
WHERE schemaname = 'public'
  AND (
    qual ILIKE '%ANY%(%'
    OR qual ILIKE '%ALL%(%'
  )
ORDER BY tablename, policyname;

-- Also check WITH CHECK clauses
SELECT
  'Table: ' || tablename as table_info,
  '  Policy: ' || policyname as policy_info,
  '  Command: ' || cmd as command_type,
  '  ❌ WITH CHECK: ' || with_check as problematic_with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND (
    with_check ILIKE '%ANY%(%'
    OR with_check ILIKE '%ALL%(%'
  )
ORDER BY tablename, policyname;

-- ============================================================================
-- EXPECTED: Should find the remaining ANY/ALL policies
-- ============================================================================
