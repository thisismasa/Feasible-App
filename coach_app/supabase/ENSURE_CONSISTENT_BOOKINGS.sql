-- ============================================================================
-- ENSURE CONSISTENT BOOKINGS FOR ALL CLIENTS
-- ============================================================================
-- This ensures that every booking (current and future) works consistently
-- for all clients like it did for แม่พี่ปุ่น
-- ============================================================================

-- STEP 1: Verify and fix book_session_with_validation function
-- This function MUST:
-- 1. Create session in 'sessions' table
-- 2. Update package remaining_sessions properly
-- 3. Work consistently for ALL clients

CREATE OR REPLACE FUNCTION book_session_with_validation(
  p_client_id UUID,
  p_trainer_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_package_id UUID,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_session_id UUID;
  v_scheduled_end TIMESTAMPTZ;
  v_package RECORD;
  v_validation_errors TEXT[] := '{}';
  v_buffer_minutes INTEGER;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_conflict RECORD;
  v_has_conflicts BOOLEAN := FALSE;
BEGIN
  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;

  -- Get buffer time
  v_buffer_minutes := COALESCE(
    (SELECT buffer_minutes FROM trainer_settings WHERE trainer_id = p_trainer_id),
    15
  );
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package exists and has sessions
  SELECT
    id,
    client_id,
    total_sessions,
    used_sessions,
    remaining_sessions,
    status,
    expiry_date
  INTO v_package
  FROM client_packages
  WHERE id = p_package_id
    AND client_id = p_client_id;

  IF v_package.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package not found'
    );
  END IF;

  IF v_package.status != 'active' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package is not active (status: ' || v_package.status || ')'
    );
  END IF;

  IF v_package.expiry_date <= NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package has expired on ' || v_package.expiry_date::TEXT
    );
  END IF;

  IF v_package.remaining_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'No sessions remaining in package'
    );
  END IF;

  -- VALIDATION 2: Check not booking in the past
  IF p_scheduled_start < NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book sessions in the past'
    );
  END IF;

  -- VALIDATION 3: Check maximum advance booking (90 days)
  IF p_scheduled_start > NOW() + INTERVAL '90 days' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book more than 90 days in advance'
    );
  END IF;

  -- VALIDATION 4: Check for trainer conflicts
  SELECT COUNT(*) INTO v_has_conflicts
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (
      -- Check if new session overlaps with existing (including buffer)
      (p_scheduled_start, v_scheduled_end) OVERLAPS
      (buffer_start, buffer_end)
    );

  IF v_has_conflicts > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Trainer has another session at this time (including 15 min buffer)'
    );
  END IF;

  -- VALIDATION 5: Check for client conflicts
  SELECT COUNT(*) INTO v_has_conflicts
  FROM sessions
  WHERE client_id = p_client_id
    AND status IN ('scheduled', 'confirmed')
    AND (
      (p_scheduled_start, v_scheduled_end) OVERLAPS
      (scheduled_start, scheduled_end)
    );

  IF v_has_conflicts > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Client has another session at this time'
    );
  END IF;

  -- ✅ ALL VALIDATIONS PASSED - CREATE SESSION
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    buffer_start,
    buffer_end,
    status,
    session_type,
    location,
    client_notes,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_trainer_id,
    p_package_id,
    p_scheduled_start,
    v_scheduled_end,
    p_duration_minutes,
    v_buffer_start,
    v_buffer_end,
    'scheduled',
    p_session_type,
    p_location,
    p_notes,
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  -- ✅ UPDATE PACKAGE - Increment used_sessions
  -- The trigger will auto-calculate remaining_sessions
  UPDATE client_packages
  SET
    used_sessions = used_sessions + 1,
    updated_at = NOW()
  WHERE id = p_package_id;

  -- ✅ RETURN SUCCESS
  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'message', 'Session booked successfully',
    'buffer_minutes', v_buffer_minutes,
    'remaining_sessions', v_package.remaining_sessions - 1
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Catch any unexpected errors
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Database error: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION book_session_with_validation IS
  'Book session with validation - Works consistently for ALL clients';


-- ============================================================================
-- STEP 2: Ensure remaining_sessions trigger exists and works
-- ============================================================================

CREATE OR REPLACE FUNCTION update_remaining_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- Auto-calculate remaining_sessions = total_sessions - used_sessions
  NEW.remaining_sessions := NEW.total_sessions - NEW.used_sessions;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_remaining_sessions ON client_packages;

CREATE TRIGGER trigger_update_remaining_sessions
  BEFORE INSERT OR UPDATE ON client_packages
  FOR EACH ROW
  EXECUTE FUNCTION update_remaining_sessions();

COMMENT ON FUNCTION update_remaining_sessions IS
  'Auto-calculate remaining_sessions for ALL packages on insert/update';


-- ============================================================================
-- STEP 3: Fix any existing packages with wrong remaining_sessions
-- ============================================================================

DO $$
DECLARE
  v_fixed_count INTEGER;
BEGIN
  -- Fix all packages where remaining_sessions doesn't match calculation
  UPDATE client_packages
  SET
    remaining_sessions = total_sessions - used_sessions,
    updated_at = NOW()
  WHERE remaining_sessions != (total_sessions - used_sessions)
     OR remaining_sessions IS NULL;

  GET DIAGNOSTICS v_fixed_count = ROW_COUNT;

  RAISE NOTICE 'Fixed % packages with incorrect remaining_sessions', v_fixed_count;
END $$;


-- ============================================================================
-- STEP 4: Verify the fix works
-- ============================================================================

-- Test query: Check all packages are consistent
SELECT
  id,
  client_id,
  package_name,
  total_sessions,
  used_sessions,
  remaining_sessions,
  (total_sessions - used_sessions) as calculated_remaining,
  CASE
    WHEN remaining_sessions = (total_sessions - used_sessions) THEN '✓ CORRECT'
    ELSE '✗ WRONG'
  END as status
FROM client_packages
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 20;


-- ============================================================================
-- STEP 5: Test booking for any client (should work consistently)
-- ============================================================================

/*
-- Example test (replace with real IDs):

SELECT book_session_with_validation(
  p_client_id := '70ece1bf-8687-42cd-9bd9-871304a15859'::UUID,
  p_trainer_id := '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID,
  p_scheduled_start := '2025-10-30 15:00:00+07'::TIMESTAMPTZ,
  p_duration_minutes := 60,
  p_package_id := '7538f06e-6965-4abb-993d-dfb085d5a3fe'::UUID,
  p_session_type := 'in_person',
  p_location := NULL,
  p_notes := NULL
);

Expected result:
{
  "success": true,
  "session_id": "...",
  "message": "Session booked successfully",
  "remaining_sessions": 0
}
*/


-- ============================================================================
-- DOCUMENTATION: How Booking Works For ALL Clients
-- ============================================================================

/*
BOOKING WORKFLOW (Consistent for ALL clients):

1. User clicks "Confirm Booking" in app
2. App calls: DatabaseService.bookSession(...)
3. App calls: Supabase RPC book_session_with_validation(...)
4. Database performs these steps IN TRANSACTION:

   a) VALIDATE Package:
      - Check package exists
      - Check status = 'active'
      - Check not expired
      - Check remaining_sessions > 0

   b) VALIDATE Booking:
      - Check not in past
      - Check not too far in future
      - Check no trainer conflicts
      - Check no client conflicts

   c) CREATE Session:
      - Insert into sessions table
      - Status: 'scheduled'
      - All details saved

   d) UPDATE Package:
      - Increment used_sessions by 1
      - Trigger auto-calculates: remaining_sessions = total_sessions - used_sessions

   e) RETURN Result:
      - success: true
      - session_id: UUID
      - remaining_sessions: updated count

5. App receives response
6. App shows success dialog
7. App navigates to Booking Management → Upcoming tab
8. Session appears in list!

CONSISTENCY GUARANTEE:
- Works the same for แม่พี่ปุ่น, Nadtaporn, and ALL future clients
- No special cases or client-specific logic
- Every booking follows the same transaction flow
- Package updates are atomic and consistent
*/
