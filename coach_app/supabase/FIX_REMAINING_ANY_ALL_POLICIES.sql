-- ============================================================================
-- FIX: Remove the TWO remaining policies with ANY/ALL syntax
-- ============================================================================
-- Target policies:
-- 1. "Trainers can delete own sessions" - has ANY(ARRAY[...])
-- 2. "Trainers can update own sessions" - has ANY(ARRAY[...])

SELECT '=== STEP 1: Drop the problematic policies ===' as step;

-- Drop the two policies that have ANY/ALL
DROP POLICY IF EXISTS "Trainers can delete own sessions" ON sessions;
DROP POLICY IF EXISTS "Trainers can update own sessions" ON sessions;

SELECT '✅ Problematic policies dropped' as result;

-- ============================================================================
-- STEP 2: Recreate with IN syntax (NO ANY/ALL!)
-- ============================================================================

SELECT '=== STEP 2: Creating clean policies ===' as step;

-- Policy 1: Trainers can delete sessions
-- ✅ Use IN syntax instead of ANY(ARRAY[...])
CREATE POLICY "Trainers can delete own sessions"
ON sessions
FOR DELETE
USING (
  auth.uid() = trainer_id
  AND status IN ('scheduled', 'confirmed')  -- ✅ NOT: = ANY(ARRAY['scheduled', 'confirmed'])
);

-- Policy 2: Trainers can update sessions
-- ✅ Use IN syntax instead of ANY(ARRAY[...])
CREATE POLICY "Trainers can update own sessions"
ON sessions
FOR UPDATE
USING (
  auth.uid() = trainer_id
  AND status IN ('scheduled', 'confirmed', 'cancelled')  -- ✅ NOT: = ANY(ARRAY[...])
)
WITH CHECK (
  auth.uid() = trainer_id
);

SELECT '✅ Clean policies created' as result;

-- ============================================================================
-- STEP 3: Reload PostgREST
-- ============================================================================

SELECT '=== STEP 3: Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reloaded' as result;

-- ============================================================================
-- STEP 4: Verify ALL policies are clean
-- ============================================================================

SELECT '=== STEP 4: Final verification ===' as step;

SELECT
  policyname,
  cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ STILL HAS ANY/ALL'
    WHEN with_check LIKE '%ANY%' OR with_check LIKE '%ALL%' THEN '❌ STILL HAS ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_policies
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY policyname;

-- ============================================================================
-- EXPECTED RESULT: ALL policies should show ✅ Clean
-- Then test cancel button - error should be GONE!
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'All ANY/ALL removed. NOW test cancel button!' as next_step;
