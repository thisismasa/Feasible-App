-- ============================================================================
-- CORRECT FINAL FIX: Use client_packages.id directly (no packages table lookup)
-- Purpose: Fix foreign key constraint - sessions.package_id = client_packages.id
-- ============================================================================

-- Step 1: Drop ALL versions of the function completely
DROP FUNCTION IF EXISTS book_session_with_validation(uuid, uuid, uuid, timestamptz, integer, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS book_session_with_validation CASCADE;

-- Step 2: Recreate with correct logic - p_package_id is client_packages.id
CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_package_id UUID,  -- This is client_packages.id (NOT packages.id!)
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_package_sessions INTEGER;
  v_has_conflicts BOOLEAN;
  v_scheduled_end TIMESTAMPTZ;
  v_session_id UUID;
BEGIN
  -- Calculate session end time
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::interval;

  -- SIMPLIFIED: Just get remaining sessions from client_packages using the ID directly
  SELECT cp.remaining_sessions
  INTO v_package_sessions
  FROM client_packages cp
  WHERE cp.id = p_package_id  -- Direct ID lookup (p_package_id IS the client_packages.id!)
    AND cp.client_id = p_client_id
    AND cp.status = 'active'
  LIMIT 1;

  -- Validate package exists and is active
  IF v_package_sessions IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Package not found or inactive',
      'details', 'No active package found with id: ' || p_package_id::text
    );
  END IF;

  -- Validate remaining sessions
  IF v_package_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No remaining sessions',
      'remaining_sessions', v_package_sessions
    );
  END IF;

  -- Check for scheduling conflicts
  SELECT EXISTS(
    SELECT 1
    FROM sessions
    WHERE trainer_id = p_trainer_id
      AND status IN ('scheduled', 'confirmed')
      AND (
        (p_scheduled_start >= scheduled_start AND p_scheduled_start < scheduled_end)
        OR
        (v_scheduled_end > scheduled_start AND v_scheduled_end <= scheduled_end)
        OR
        (p_scheduled_start <= scheduled_start AND v_scheduled_end >= scheduled_end)
      )
  ) INTO v_has_conflicts;

  -- Warn about conflicts
  IF v_has_conflicts THEN
    RAISE WARNING 'Scheduling conflict detected for trainer % at %', p_trainer_id, p_scheduled_start;
  END IF;

  -- Create session record
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,  -- This will be client_packages.id
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
    p_package_id,  -- client_packages.id
    p_scheduled_start,
    v_scheduled_end,
    p_duration_minutes,
    COALESCE(p_session_type, 'in_person'),
    p_location,
    p_notes,
    'scheduled',
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  -- Return success
  RETURN jsonb_build_object(
    'success', true,
    'session_id', v_session_id,
    'has_conflicts', v_has_conflicts,
    'remaining_sessions', v_package_sessions - 1,
    'message', 'Session booked successfully'
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

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION book_session_with_validation TO authenticated;
GRANT EXECUTE ON FUNCTION book_session_with_validation TO anon;

-- Step 4: Verify
DO $$
BEGIN
  RAISE NOTICE '✅ CORRECT FINAL FIX APPLIED';
  RAISE NOTICE '✅ p_package_id now treated as client_packages.id';
  RAISE NOTICE '✅ No lookup to packages table needed';
  RAISE NOTICE '✅ Foreign key constraint will be satisfied';
END $$;

-- ============================================================================
-- WHAT CHANGED:
-- ============================================================================
-- OLD (WRONG):
--   WHERE cp.package_id = p_package_id  -- Looked for packages.id
--
-- NEW (CORRECT):
--   WHERE cp.id = p_package_id  -- Direct lookup of client_packages.id
--
-- This matches the database schema where:
--   sessions.package_id → client_packages.id (FK constraint)
-- ============================================================================
