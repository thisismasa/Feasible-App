-- ============================================================================
-- SIMPLE: Just show RLS policies on sessions table
-- ============================================================================
-- The ANY/ALL error is coming from RLS policies, not functions!

SELECT
  tablename,
  policyname,
  cmd as command,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY policyname;

-- This will show ALL policies on the sessions table
-- Look for ANY/ALL syntax in the using_expression or with_check columns
