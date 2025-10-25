-- ============================================================================
-- VERIFY: Was the Database Fix Actually Applied?
-- ============================================================================

SELECT '=== STEP 1: Check if booking function exists ===' as step;

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  prosrc as source_code_preview
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 2: Check if function source contains conflict detection
-- ============================================================================

SELECT '=== STEP 2: Does function have conflict detection? ===' as step;

SELECT
  proname as function_name,
  CASE
    WHEN prosrc LIKE '%You already have a session booked at this time%'
    THEN '✅ YES - Client conflict detection found'
    ELSE '❌ NO - Conflict detection MISSING!'
  END as has_client_conflict_check,
  CASE
    WHEN prosrc LIKE '%Trainer is already booked at this time%'
    THEN '✅ YES - Trainer conflict detection found'
    ELSE '❌ NO - Trainer conflict detection MISSING!'
  END as has_trainer_conflict_check
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- STEP 3: Get exact line showing conflict check (if exists)
-- ============================================================================

SELECT '=== STEP 3: Show conflict detection code ===' as step;

SELECT
  proname as function_name,
  SUBSTRING(
    prosrc
    FROM 'SELECT COUNT\(\*\)[\s\S]*?FROM sessions[\s\S]*?WHERE client_id.*?scheduled'
  ) as client_conflict_code_snippet
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- STEP 1: Should show function exists
-- STEP 2: Should show ✅ YES for BOTH checks
-- STEP 3: Should show SELECT COUNT(*) code checking for conflicts
--
-- IF ANY STEP FAILS:
--   The database fix was NOT applied properly
--   Need to re-run FIX_DOUBLE_BOOKING_DATABASE.sql
-- ============================================================================
