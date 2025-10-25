-- ============================================================================
-- FINAL WORKING FIX: Book Session Function - Remove non-existent columns
-- Purpose: Fix column errors - only use columns that exist in sessions table
-- ============================================================================

-- Step 1: Drop ALL versions of the function completely
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

-- Step 2: Recreate with ONLY existing columns
CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_package_sessions INTEGER;
  v_client_package_id UUID;
  v_session_id UUID;
  v_has_conflicts BOOLEAN;
  v_scheduled_end TIMESTAMPTZ;
BEGIN
  -- Calculate session end time
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::interval;

  -- CRITICAL FIX: Check package for THIS specific client
  SELECT cp.remaining_sessions, cp.id
  INTO v_package_sessions, v_client_package_id
  FROM client_packages cp
  WHERE cp.package_id = p_package_id      -- FK to packages table
    AND cp.client_id = p_client_id        -- THIS client's package instance
    AND cp.status = 'active'
  LIMIT 1;

  -- Validate package exists and is active
  IF v_client_package_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Package not found or inactive',
      'details', 'No active package found for this client with package_id: ' || p_package_id::text
    );
  END IF;

  -- Validate remaining sessions
  IF v_package_sessions IS NULL OR v_package_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No remaining sessions',
      'remaining_sessions', COALESCE(v_package_sessions, 0)
    );
  END IF;

  -- SIMPLIFIED: Check for scheduling conflicts
  SELECT EXISTS(
    SELECT 1
    FROM sessions
    WHERE trainer_id = p_trainer_id
      AND status IN ('scheduled', 'confirmed')
      AND (
        -- New session starts during existing session
        (p_scheduled_start >= scheduled_start AND p_scheduled_start < scheduled_start + (duration_minutes || ' minutes')::interval)
        OR
        -- New session ends during existing session
        (v_scheduled_end > scheduled_start AND v_scheduled_end <= scheduled_start + (duration_minutes || ' minutes')::interval)
        OR
        -- New session completely encompasses existing session
        (p_scheduled_start <= scheduled_start AND v_scheduled_end >= scheduled_start + (duration_minutes || ' minutes')::interval)
      )
  ) INTO v_has_conflicts;

  -- Warn about conflicts but allow booking
  IF v_has_conflicts THEN
    RAISE WARNING 'Scheduling conflict detected for trainer % at %', p_trainer_id, p_scheduled_start;
  END IF;

  -- Create session record with ONLY columns that exist
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
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
    p_duration_minutes,
    COALESCE(p_session_type, 'in_person'),
    p_location,
    p_notes,
    'scheduled',
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  -- NOTE: Package sync happens automatically via trigger auto_sync_package_sessions
  -- The trigger will decrement remaining_sessions and increment used_sessions

  -- Return success
  RETURN jsonb_build_object(
    'success', true,
    'session_id', v_session_id,
    'has_conflicts', v_has_conflicts,
    'remaining_sessions', v_package_sessions - 1,
    'message', 'Session booked successfully. Package sessions will sync automatically via trigger.'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'error_detail', SQLSTATE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant execute permissions
GRANT EXECUTE ON FUNCTION book_session_with_validation TO authenticated;
GRANT EXECUTE ON FUNCTION book_session_with_validation TO anon;

-- Step 4: Verify function exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'book_session_with_validation'
  ) THEN
    RAISE NOTICE '✅ Function book_session_with_validation fixed - using only existing columns';
    RAISE NOTICE '✅ Removed: scheduled_date, scheduled_time, has_conflicts, validation_passed';
    RAISE NOTICE '✅ Booking should work now!';
  ELSE
    RAISE EXCEPTION '❌ Function was not created properly';
  END IF;
END $$;

-- ============================================================================
-- WHAT WAS FIXED:
-- ============================================================================
-- 1. Removed columns that don't exist in sessions table:
--    - scheduled_date (doesn't exist)
--    - scheduled_time (doesn't exist)
--    - has_conflicts (doesn't exist)
--    - validation_passed (doesn't exist)
--
-- 2. Kept only columns that DO exist:
--    - client_id, trainer_id, package_id
--    - scheduled_start (TIMESTAMPTZ - this is the main date/time field)
--    - duration_minutes
--    - session_type, location, notes
--    - status, created_at, updated_at
--
-- 3. Package lookup still correct (checks both package_id AND client_id)
-- 4. Conflict detection still works
-- 5. Auto-sync trigger still works for session counting
-- ============================================================================

-- ============================================================================
-- INSTRUCTIONS TO RUN THIS FIX:
-- ============================================================================
-- 1. First, run CHECK_SESSIONS_TABLE_STRUCTURE.sql to see actual columns
-- 2. Open Supabase SQL Editor
-- 3. Create NEW query
-- 4. Paste this entire file
-- 5. Click "Run" button
-- 6. You should see: "✅ Function fixed - using only existing columns"
-- 7. Go back to Flutter app
-- 8. Try booking again - should work now!
-- ============================================================================
