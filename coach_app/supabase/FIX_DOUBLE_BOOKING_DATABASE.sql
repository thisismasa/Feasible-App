-- ============================================================================
-- FIX: Prevent Double-Booking at Database Level
-- ============================================================================
-- This adds conflict detection to book_session_with_validation function
-- Prevents: Same client booking same time twice
-- Prevents: Trainer being double-booked
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

SELECT '✅ Old booking function dropped' as step_1;

-- ============================================================================
-- Create NEW booking function with conflict detection
-- ============================================================================

CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_package_id UUID,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_package_sessions INTEGER;
  v_scheduled_end TIMESTAMPTZ;
  v_new_session_id UUID;
  v_conflict_count INTEGER;
BEGIN
  -- Calculate end time
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- ============================================================================
  -- NEW: Check if CLIENT already has a session at this time
  -- ============================================================================
  SELECT COUNT(*)
  INTO v_conflict_count
  FROM sessions
  WHERE client_id = p_client_id
    AND status IN ('scheduled', 'confirmed')
    AND (
      -- Check for ANY time overlap
      (scheduled_start < v_scheduled_end AND scheduled_end > p_scheduled_start)
    );

  IF v_conflict_count > 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'You already have a session booked at this time',
      'message', 'You already have a session booked at this time. Please choose a different time slot.'
    );
  END IF;

  -- ============================================================================
  -- NEW: Check if TRAINER already has a session at this time
  -- ============================================================================
  SELECT COUNT(*)
  INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (
      -- Check for ANY time overlap
      (scheduled_start < v_scheduled_end AND scheduled_end > p_scheduled_start)
    );

  IF v_conflict_count > 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Trainer is already booked at this time',
      'message', 'This time slot is no longer available. Please choose a different time.'
    );
  END IF;

  -- ============================================================================
  -- Check package has remaining sessions (existing logic)
  -- ============================================================================
  SELECT cp.remaining_sessions
  INTO v_package_sessions
  FROM client_packages cp
  WHERE cp.id = p_package_id
    AND cp.client_id = p_client_id
    AND cp.status = 'active'
  LIMIT 1;

  IF v_package_sessions IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Package not found or inactive',
      'message', 'Package not found or inactive'
    );
  END IF;

  IF v_package_sessions <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'No remaining sessions in package',
      'message', 'No remaining sessions in package'
    );
  END IF;

  -- ============================================================================
  -- Create session (existing logic)
  -- ============================================================================
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    session_type,
    location,
    notes,
    status,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    p_scheduled_start,
    v_scheduled_end,
    p_duration_minutes,
    p_session_type,
    p_location,
    p_notes,
    'scheduled',
    NOW(),
    NOW()
  )
  RETURNING id INTO v_new_session_id;

  RETURN json_build_object(
    'success', TRUE,
    'session_id', v_new_session_id,
    'message', 'Session booked successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM,
      'message', 'Failed to book session: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '✅ New booking function created with conflict detection' as step_2;

-- ============================================================================
-- Grant permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION book_session_with_validation TO authenticated;

SELECT '✅ Permissions granted' as step_3;

-- ============================================================================
-- Test the conflict detection
-- ============================================================================

SELECT '=== TEST CONFLICT DETECTION ===' as test_section;

-- Get a session that exists
WITH test_session AS (
  SELECT
    client_id,
    trainer_id,
    scheduled_start,
    duration_minutes,
    package_id
  FROM sessions
  WHERE status IN ('scheduled', 'confirmed')
  ORDER BY scheduled_start DESC
  LIMIT 1
)
SELECT
  'Attempting to book duplicate session...' as test_description,
  book_session_with_validation(
    (SELECT client_id FROM test_session),
    (SELECT trainer_id FROM test_session),
    (SELECT scheduled_start FROM test_session),
    (SELECT duration_minutes FROM test_session),
    (SELECT package_id FROM test_session),
    'in_person',
    'Test Location',
    'Testing conflict detection'
  ) as test_result;

-- ============================================================================
-- EXPECTED TEST RESULT:
-- ============================================================================
-- {
--   "success": false,
--   "error": "You already have a session booked at this time",
--   "message": "You already have a session booked at this time..."
-- }
--
-- If test shows success: FALSE with conflict error, then fix is working!
-- ============================================================================

-- ============================================================================
-- Verify function exists
-- ============================================================================

SELECT
  proname as function_name,
  pg_get_function_arguments(oid) as parameters,
  '✅ Ready with conflict detection' as status
FROM pg_proc
WHERE proname = 'book_session_with_validation'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- WHAT WAS FIXED:
-- ============================================================================
-- 1. ✅ Added CLIENT conflict check
--    - Prevents same client from booking duplicate times
--    - Checks for ANY time overlap
--
-- 2. ✅ Added TRAINER conflict check
--    - Prevents trainer from being double-booked
--    - Checks for ANY time overlap
--
-- 3. ✅ Clear error messages
--    - User-friendly messages for each conflict type
--    - Distinguishes between client vs trainer conflicts
--
-- 4. ✅ Proper time overlap detection
--    - Uses: (start1 < end2 AND end1 > start2)
--    - Catches all overlap scenarios
-- ============================================================================

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 1. Run this SQL in Supabase
-- 2. Restart Flutter app
-- 3. Try booking duplicate 15:30 session
-- 4. Should fail with: "You already have a session booked at this time"
-- 5. Verify in Booking Management - no new duplicate created
-- ============================================================================
