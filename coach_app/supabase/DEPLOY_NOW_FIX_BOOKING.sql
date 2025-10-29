-- ============================================================================
-- DEPLOY NOW - FIX BOOKING ERRORS
-- ============================================================================
-- This script fixes the "Unknown error" issue and makes bookings work
-- Run this in Supabase SQL Editor NOW
-- ============================================================================

-- STEP 1: Deploy the correct booking function with proper error messages
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
  v_buffer_minutes INTEGER := 15;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_conflict_count INTEGER;
BEGIN
  -- Log booking attempt
  RAISE NOTICE '⏳ Booking attempt: client=%, trainer=%, time=%', p_client_id, p_trainer_id, p_scheduled_start;

  v_scheduled_end := p_scheduled_start + (p_duration_minutes || ' minutes')::INTERVAL;
  v_buffer_start := p_scheduled_start - (v_buffer_minutes || ' minutes')::INTERVAL;
  v_buffer_end := v_scheduled_end + (v_buffer_minutes || ' minutes')::INTERVAL;

  -- VALIDATION 1: Check package
  SELECT id, client_id, total_sessions, used_sessions, remaining_sessions, status, expiry_date
  INTO v_package
  FROM client_packages
  WHERE id = p_package_id;

  IF v_package.id IS NULL THEN
    RAISE NOTICE '❌ Package not found: %', p_package_id;
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package not found with ID: ' || p_package_id::TEXT,
      'errors', ARRAY['Package not found']
    );
  END IF;

  IF v_package.client_id != p_client_id THEN
    RAISE NOTICE '❌ Package belongs to wrong client';
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'This package does not belong to the selected client',
      'errors', ARRAY['Package does not belong to this client']
    );
  END IF;

  IF v_package.status != 'active' THEN
    RAISE NOTICE '❌ Package not active: %', v_package.status;
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package is not active (current status: ' || v_package.status || ')',
      'errors', ARRAY['Package is not active']
    );
  END IF;

  IF v_package.expiry_date <= NOW() THEN
    RAISE NOTICE '❌ Package expired: %', v_package.expiry_date;
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Package expired on ' || to_char(v_package.expiry_date, 'DD Mon YYYY'),
      'errors', ARRAY['Package has expired']
    );
  END IF;

  IF v_package.remaining_sessions <= 0 THEN
    RAISE NOTICE '❌ No sessions remaining';
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'No sessions remaining in this package',
      'errors', ARRAY['No sessions remaining in package']
    );
  END IF;

  RAISE NOTICE '✓ Package valid: % sessions remaining', v_package.remaining_sessions;

  -- VALIDATION 2: Not in past
  IF p_scheduled_start < NOW() THEN
    RAISE NOTICE '❌ Booking in past';
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cannot book sessions in the past',
      'errors', ARRAY['Cannot book sessions in the past']
    );
  END IF;

  -- VALIDATION 3: Trainer conflicts
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE trainer_id = p_trainer_id
    AND status IN ('scheduled', 'confirmed')
    AND (p_scheduled_start, v_scheduled_end) OVERLAPS (buffer_start, buffer_end);

  IF v_conflict_count > 0 THEN
    RAISE NOTICE '❌ Trainer conflict detected';
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Trainer has another session at this time (including 15 min buffer)',
      'errors', ARRAY['Trainer has another session at this time']
    );
  END IF;

  -- VALIDATION 4: Client conflicts
  SELECT COUNT(*) INTO v_conflict_count
  FROM sessions
  WHERE client_id = p_client_id
    AND status IN ('scheduled', 'confirmed')
    AND (p_scheduled_start, v_scheduled_end) OVERLAPS (scheduled_start, scheduled_end);

  IF v_conflict_count > 0 THEN
    RAISE NOTICE '❌ Client conflict detected';
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Client has another session at this time',
      'errors', ARRAY['Client has another session at this time']
    );
  END IF;

  RAISE NOTICE '✓ All validations passed, creating session';

  -- CREATE SESSION
  INSERT INTO sessions (
    client_id, trainer_id, package_id,
    scheduled_start, scheduled_end, duration_minutes,
    buffer_start, buffer_end,
    status, session_type, location, client_notes,
    created_at, updated_at
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_scheduled_start, v_scheduled_end, p_duration_minutes,
    v_buffer_start, v_buffer_end,
    'scheduled', p_session_type, p_location, p_notes,
    NOW(), NOW()
  ) RETURNING id INTO v_session_id;

  -- UPDATE PACKAGE
  UPDATE client_packages
  SET
    used_sessions = used_sessions + 1,
    remaining_sessions = remaining_sessions - 1,
    updated_at = NOW()
  WHERE id = p_package_id;

  RAISE NOTICE '✅ Session created: %', v_session_id;

  -- RETURN SUCCESS
  RETURN jsonb_build_object(
    'success', TRUE,
    'session_id', v_session_id,
    'message', 'Session booked successfully',
    'remaining_sessions', v_package.remaining_sessions - 1
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Exception: %', SQLERRM;
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Database error: ' || SQLERRM,
      'errors', ARRAY['Database error: ' || SQLERRM]
    );
END;
$$ LANGUAGE plpgsql;

-- STEP 2: Fix all packages with wrong remaining_sessions
DO $$
DECLARE
  v_fixed_count INTEGER;
BEGIN
  UPDATE client_packages
  SET
    remaining_sessions = total_sessions - used_sessions,
    updated_at = NOW()
  WHERE remaining_sessions != (total_sessions - used_sessions)
     OR remaining_sessions IS NULL;

  GET DIAGNOSTICS v_fixed_count = ROW_COUNT;
  RAISE NOTICE '✅ Fixed % packages', v_fixed_count;
END $$;


-- STEP 3: Activate any inactive packages that should be active
UPDATE client_packages
SET status = 'active'
WHERE status != 'active'
  AND expiry_date > NOW()
  AND remaining_sessions > 0;


-- STEP 4: Test with P' Ae's package
DO $$
DECLARE
  v_result JSONB;
  v_package RECORD;
BEGIN
  -- Check P' Ae's package
  SELECT * INTO v_package
  FROM client_packages
  WHERE id = 'bb5fef0f-aae0-41d2-a838-f9fb6291b863';

  RAISE NOTICE '========== P'' Ae Package Status ==========';
  RAISE NOTICE 'Package Name: %', v_package.package_name;
  RAISE NOTICE 'Status: %', v_package.status;
  RAISE NOTICE 'Total Sessions: %', v_package.total_sessions;
  RAISE NOTICE 'Used Sessions: %', v_package.used_sessions;
  RAISE NOTICE 'Remaining Sessions: %', v_package.remaining_sessions;
  RAISE NOTICE 'Expiry Date: %', v_package.expiry_date;
  RAISE NOTICE 'Ready to book: %',
    CASE
      WHEN v_package.status = 'active'
        AND v_package.expiry_date > NOW()
        AND v_package.remaining_sessions > 0
      THEN '✅ YES'
      ELSE '❌ NO'
    END;
END $$;


-- STEP 5: Verify both clients' packages
SELECT
  '========== ALL CLIENT PACKAGES ==========' as section,
  u.full_name as client_name,
  cp.package_name,
  cp.status,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.expiry_date,
  CASE
    WHEN cp.status != 'active' THEN '❌ Not active'
    WHEN cp.expiry_date <= NOW() THEN '❌ Expired'
    WHEN cp.remaining_sessions <= 0 THEN '❌ No sessions'
    ELSE '✅ READY TO BOOK'
  END as booking_ready
FROM client_packages cp
LEFT JOIN users u ON u.id = cp.client_id
WHERE cp.id IN (
  'ece5c8e5-1c0a-41c4-9c86-c9197fe08afd',  -- p'Poon
  'bb5fef0f-aae0-41d2-a838-f9fb6291b863'   -- P' Ae
)
ORDER BY u.full_name;


-- STEP 6: Show completion message
SELECT
  '========================================' as message
UNION ALL SELECT '✅ DEPLOYMENT COMPLETE'
UNION ALL SELECT '========================================'
UNION ALL SELECT 'Next steps:'
UNION ALL SELECT '1. Restart your Flutter app'
UNION ALL SELECT '2. Try booking for P'' Ae or p''Poon'
UNION ALL SELECT '3. You should see specific error messages (not "Unknown error")'
UNION ALL SELECT '4. If package is ready, booking will succeed';
