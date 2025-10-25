-- ============================================================================
-- QUICK VERIFICATION: Did the fix work?
-- ============================================================================

SELECT
  policyname,
  cmd,
  qual as using_expression,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ STILL HAS ANY/ALL'
    ELSE '✅ CLEAN'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('Trainers can delete own sessions', 'Trainers can update own sessions')
ORDER BY policyname;

-- ============================================================================
-- If BOTH show ✅ CLEAN, the database is fixed!
-- If EITHER shows ❌, the fix failed
-- ============================================================================
