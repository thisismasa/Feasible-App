-- ============================================================================
-- FIX: Remove ANY/ALL syntax from RLS policies on sessions table
-- ============================================================================
-- This replaces ANY/ALL with IN syntax to fix the operator boolean error

SELECT '=== STEP 1: Drop existing RLS policies ===' as step;

-- Drop all policies on sessions table (we'll recreate them)
DROP POLICY IF EXISTS "Trainers can view own sessions" ON sessions;
DROP POLICY IF EXISTS "Trainers can create sessions" ON sessions;
DROP POLICY IF EXISTS "Trainers can update own sessions" ON sessions;
DROP POLICY IF EXISTS "Trainers can delete own sessions" ON sessions;
DROP POLICY IF EXISTS "Clients can view own sessions" ON sessions;
DROP POLICY IF EXISTS "Users can view their sessions" ON sessions;
DROP POLICY IF EXISTS "Users can manage their sessions" ON sessions;

SELECT '✅ Old policies dropped' as result;

-- ============================================================================
-- STEP 2: Recreate policies with correct IN syntax (NO ANY/ALL!)
-- ============================================================================

SELECT '=== STEP 2: Creating new RLS policies ===' as step;

-- Policy 1: Trainers can view their own sessions
CREATE POLICY "Trainers can view own sessions"
ON sessions
FOR SELECT
USING (
  auth.uid() = trainer_id
);

-- Policy 2: Clients can view their own sessions
CREATE POLICY "Clients can view own sessions"
ON sessions
FOR SELECT
USING (
  auth.uid() = client_id
);

-- Policy 3: Trainers can insert sessions
CREATE POLICY "Trainers can create sessions"
ON sessions
FOR INSERT
WITH CHECK (
  auth.uid() = trainer_id
);

-- Policy 4: Trainers can update their sessions
-- ✅ IMPORTANT: Use IN syntax, NOT ANY/ALL!
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

-- Policy 5: Trainers can delete their sessions
CREATE POLICY "Trainers can delete own sessions"
ON sessions
FOR DELETE
USING (
  auth.uid() = trainer_id
  AND status IN ('scheduled', 'confirmed')  -- ✅ NOT: = ANY(ARRAY[...])
);

SELECT '✅ New policies created with IN syntax' as result;

-- ============================================================================
-- STEP 3: Verify RLS is enabled
-- ============================================================================

SELECT '=== STEP 3: Verify RLS ===' as step;

-- Show RLS status
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'sessions'
  AND schemaname = 'public';

-- Show all policies
SELECT
  policyname,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY policyname;

-- ============================================================================
-- STEP 4: Reload PostgREST schema
-- ============================================================================

SELECT '=== STEP 4: Reloading PostgREST ===' as step;

NOTIFY pgrst, 'reload schema';

SELECT '✅ PostgREST notified to reload' as result;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- 1. All RLS policies recreated with IN syntax (no ANY/ALL)
-- 2. PostgREST reloaded with new policies
-- 3. Cancel button should work without ANY/ALL error
-- 4. Test by clicking cancel button in Flutter UI
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'RLS policies fixed. Test cancel button now!' as next_step;
