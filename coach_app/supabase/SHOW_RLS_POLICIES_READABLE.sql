-- ============================================================================
-- SHOW: RLS Policies on sessions table in readable format
-- ============================================================================
-- This query shows each policy on a separate row for easy reading

SELECT
  '=== Policy: ' || policyname || ' ===' as info,
  'Command: ' || cmd as command_type,
  'USING expression: ' || COALESCE(qual, 'none') as using_clause,
  'WITH CHECK expression: ' || COALESCE(with_check, 'none') as with_check_clause
FROM pg_policies
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY policyname;

-- ============================================================================
-- Look for ANY/ALL syntax in the expressions above
-- If you see "= ANY(ARRAY[" or "= ALL(ARRAY[" - that's the problem!
-- Should be: status IN ('scheduled', 'confirmed')
-- NOT: status = ANY(ARRAY['scheduled', 'confirmed'])
-- ============================================================================
