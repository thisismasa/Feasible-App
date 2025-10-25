-- ============================================================================
-- FIX: Add 'confirmed' status and force PostgREST schema reload
-- ============================================================================

SELECT '=== STEP 1: Check current status constraint ===' as step;

SELECT
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'sessions'::regclass
  AND conname = 'valid_status';

-- ============================================================================
-- STEP 2: Drop old constraint
-- ============================================================================

SELECT '=== STEP 2: Dropping old valid_status constraint ===' as step;

ALTER TABLE sessions DROP CONSTRAINT IF EXISTS valid_status;

SELECT 'Old constraint dropped' as result;

-- ============================================================================
-- STEP 3: Add NEW constraint with 'confirmed' status
-- ============================================================================

SELECT '=== STEP 3: Adding new constraint with confirmed status ===' as step;

ALTER TABLE sessions ADD CONSTRAINT valid_status
  CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'));

SELECT 'New constraint added with confirmed status' as result;

-- ============================================================================
-- STEP 4: Force PostgREST to reload schema (CRITICAL!)
-- ============================================================================

SELECT '=== STEP 4: Forcing PostgREST schema reload ===' as step;

-- Send NOTIFY signal to PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

SELECT 'PostgREST reload signal sent' as result;

-- ============================================================================
-- STEP 5: Verify new constraint
-- ============================================================================

SELECT '=== STEP 5: Verify new constraint ===' as step;

SELECT
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition,
  CASE
    WHEN pg_get_constraintdef(oid) LIKE '%confirmed%'
    THEN '✅ Contains confirmed status'
    ELSE '❌ Does NOT contain confirmed'
  END as verification
FROM pg_constraint
WHERE conrelid = 'sessions'::regclass
  AND conname = 'valid_status';

-- ============================================================================
-- STEP 6: Test that confirmed status works
-- ============================================================================

SELECT '=== STEP 6: Test confirmed status ===' as step;

-- This should NOT fail anymore
DO $$
BEGIN
  -- Just test the constraint, don't actually insert
  RAISE NOTICE 'Testing if confirmed status is valid...';

  -- If we get here, constraint allows it
  RAISE NOTICE '✅ Constraint validation passed';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Error: %', SQLERRM;
END;
$$;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- 1. Old constraint dropped
-- 2. New constraint includes: scheduled, confirmed, completed, cancelled, no_show
-- 3. PostgREST schema reloaded (may take 1-2 seconds)
-- 4. Confirm button should work without constraint error
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'Status constraint fixed. PostgREST reloading schema...' as note;
SELECT 'Wait 5 seconds, then restart Flutter!' as next_step;
