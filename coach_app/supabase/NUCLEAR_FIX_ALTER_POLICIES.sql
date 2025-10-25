-- ============================================================================
-- NUCLEAR FIX: Use ALTER POLICY to modify in-place
-- ============================================================================
-- DROP/CREATE isn't working - maybe Supabase is recreating from cache
-- Let's try ALTER POLICY instead to modify the existing policies

-- ============================================================================
-- STEP 1: Show current broken state
-- ============================================================================

SELECT '❌ BEFORE:' as step, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
  AND policyname IN ('Trainers can delete own sessions', 'Trainers can update own sessions');

-- ============================================================================
-- STEP 2: Try a completely different approach - rename the policies first
-- ============================================================================

SELECT '=== Renaming old policies ===' as step;

ALTER POLICY "Trainers can delete own sessions" ON sessions RENAME TO "TEMP_OLD_DELETE";
ALTER POLICY "Trainers can update own sessions" ON sessions RENAME TO "TEMP_OLD_UPDATE";

SELECT '✅ Renamed old policies' as result;

-- ============================================================================
-- STEP 3: Create NEW policies with different names and IN syntax
-- ============================================================================

SELECT '=== Creating new policies with clean names ===' as step;

-- New DELETE policy with IN syntax
CREATE POLICY "trainers_delete_sessions"
ON sessions
FOR DELETE
USING (
  auth.uid() = trainer_id
  AND status IN ('scheduled', 'confirmed')
);

-- New UPDATE policy with IN syntax
CREATE POLICY "trainers_update_sessions"
ON sessions
FOR UPDATE
USING (
  auth.uid() = trainer_id
  AND status IN ('scheduled', 'confirmed', 'cancelled')
)
WITH CHECK (
  auth.uid() = trainer_id
);

SELECT '✅ Created new policies with clean syntax' as result;

-- ============================================================================
-- STEP 4: Drop the old renamed policies
-- ============================================================================

SELECT '=== Dropping old renamed policies ===' as step;

DROP POLICY IF EXISTS "TEMP_OLD_DELETE" ON sessions;
DROP POLICY IF EXISTS "TEMP_OLD_UPDATE" ON sessions;

SELECT '✅ Dropped old policies' as result;

-- ============================================================================
-- STEP 5: Reload PostgREST
-- ============================================================================

SELECT '=== Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST reloaded' as result;

-- ============================================================================
-- STEP 6: Verify fix
-- ============================================================================

SELECT '✅ AFTER FIX:' as step, policyname, cmd,
  CASE
    WHEN qual LIKE '%ANY%' OR qual LIKE '%ALL%' THEN '❌ HAS ANY/ALL'
    ELSE '✅ CLEAN'
  END as status,
  qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'sessions'
ORDER BY policyname;

-- ============================================================================
-- COMPLETE
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'Check above - new policies should be trainers_delete_sessions and trainers_update_sessions with ✅ CLEAN status' as next_step;
