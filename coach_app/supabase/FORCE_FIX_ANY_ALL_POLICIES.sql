-- ============================================================================
-- FORCE FIX: Aggressively remove and recreate policies with ANY/ALL
-- ============================================================================
-- The previous fix didn't work - policies still have ANY/ALL syntax
-- This script will be more aggressive

-- ============================================================================
-- STEP 1: Show current problematic policies
-- ============================================================================

SELECT '❌ BEFORE FIX - These policies have ANY/ALL:' as status;

SELECT
  tablename,
  policyname,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('Trainers can delete own sessions', 'Trainers can update own sessions')
ORDER BY policyname;

-- ============================================================================
-- STEP 2: FORCE DROP with CASCADE
-- ============================================================================

SELECT '=== STEP 2: Force dropping policies ===' as step;

DROP POLICY IF EXISTS "Trainers can delete own sessions" ON sessions CASCADE;
DROP POLICY IF EXISTS "Trainers can update own sessions" ON sessions CASCADE;

SELECT '✅ Policies force dropped' as result;

-- ============================================================================
-- STEP 3: Wait a moment to ensure PostgreSQL processes the drop
-- ============================================================================

SELECT pg_sleep(1);

-- ============================================================================
-- STEP 4: Create NEW policies with CLEAN IN syntax
-- ============================================================================

SELECT '=== STEP 4: Creating clean policies with IN syntax ===' as step;

-- Policy 1: DELETE policy with IN syntax
CREATE POLICY "Trainers can delete own sessions"
ON sessions
FOR DELETE
USING (
  (auth.uid() = trainer_id)
  AND
  (status IN ('scheduled', 'confirmed'))  -- ✅ CLEAN IN SYNTAX
);

SELECT '✅ Created DELETE policy' as result;

-- Policy 2: UPDATE policy with IN syntax
CREATE POLICY "Trainers can update own sessions"
ON sessions
FOR UPDATE
USING (
  (auth.uid() = trainer_id)
  AND
  (status IN ('scheduled', 'confirmed', 'cancelled'))  -- ✅ CLEAN IN SYNTAX
)
WITH CHECK (
  auth.uid() = trainer_id
);

SELECT '✅ Created UPDATE policy' as result;

-- ============================================================================
-- STEP 5: FORCE reload PostgREST multiple times
-- ============================================================================

SELECT '=== STEP 5: Force reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(0.5);
NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reload notifications sent 3 times' as result;

-- ============================================================================
-- STEP 6: Verify the fix
-- ============================================================================

SELECT '=== STEP 6: VERIFICATION ===' as step;

SELECT
  '✅ AFTER FIX:' as status,
  tablename,
  policyname,
  cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ STILL HAS ANY/ALL - FIX FAILED!'
    ELSE '✅ CLEAN - NO ANY/ALL'
  END as check_result,
  qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('Trainers can delete own sessions', 'Trainers can update own sessions')
ORDER BY policyname;

-- ============================================================================
-- STEP 7: Show ALL policies on sessions table
-- ============================================================================

SELECT '=== STEP 7: All policies on sessions table ===' as step;

SELECT
  policyname,
  cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    ELSE '✅ Clean'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
ORDER BY policyname;

-- ============================================================================
-- EXPECTED RESULT: ALL should show ✅ Clean
-- If you still see ❌, then there's a caching issue with PostgREST
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'If all are ✅, restart Flutter and test cancel button!' as next_step;
