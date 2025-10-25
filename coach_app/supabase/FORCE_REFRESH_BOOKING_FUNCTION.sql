-- ============================================================================
-- FORCE REFRESH: Book Session Function (Updated at 2025-10-24)
-- Purpose: Forcefully refresh Supabase's cache of this function
-- ============================================================================

-- Step 1: Drop ALL versions of the function completely
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

-- Step 2: Recreate with CORRECT package lookup logic
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
  v_conflict_sessions JSONB;
BEGIN
  -- Updated: 2025-10-24 - Force cache refresh

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

  -- Check for scheduling conflicts
  SELECT
    EXISTS(
      SELECT 1 FROM sessions
      WHERE trainer_id = p_trainer_id
        AND status IN ('scheduled', 'confirmed')
        AND tsrange(scheduled_start, scheduled_start + (duration_minutes || ' minutes')::interval, '[)')
        && tsrange(p_scheduled_start, p_scheduled_start + (p_duration_minutes || ' minutes')::interval, '[)')
    ),
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'session_id', id,
          'client_name', (SELECT full_name FROM users WHERE id = client_id),
          'scheduled_start', scheduled_start,
          'duration_minutes', duration_minutes
        )
      ) FILTER (WHERE id IS NOT NULL),
      '[]'::jsonb
    )
  INTO v_has_conflicts, v_conflict_sessions
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND tsrange(scheduled_start, scheduled_start + (duration_minutes || ' minutes')::interval, '[)')
    && tsrange(p_scheduled_start, p_scheduled_start + (p_duration_minutes || ' minutes')::interval, '[)');

  -- Warn about conflicts but allow booking (trainer can decide)
  IF v_has_conflicts THEN
    RAISE WARNING 'Scheduling conflict detected for trainer % at %', p_trainer_id, p_scheduled_start;
  END IF;

  -- Create session record
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_date,
    scheduled_time,
    duration_minutes,
    session_type,
    location,
    notes,
    status,
    has_conflicts,
    validation_passed,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    p_scheduled_start,
    p_scheduled_start::date,
    p_scheduled_start::time,
    p_duration_minutes,
    COALESCE(p_session_type, 'in_person'),
    p_location,
    p_notes,
    'scheduled',
    v_has_conflicts,
    NOT v_has_conflicts,
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
    'conflict_sessions', v_conflict_sessions,
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
    RAISE NOTICE '✅ Function book_session_with_validation has been refreshed successfully';
    RAISE NOTICE '✅ Timestamp: 2025-10-24 - Cache should be cleared';
  ELSE
    RAISE EXCEPTION '❌ Function was not created properly';
  END IF;
END $$;

-- ============================================================================
-- INSTRUCTIONS TO RUN THIS FIX:
-- ============================================================================
-- 1. Open Supabase SQL Editor
-- 2. Create NEW query (don't use old saved query)
-- 3. Paste this entire file
-- 4. Click "Run" button
-- 5. You should see: "✅ Function book_session_with_validation has been refreshed"
-- 6. Go to your Flutter app browser tab
-- 7. Press F5 to refresh the page
-- 8. Try booking again - it should work now!
-- ============================================================================
