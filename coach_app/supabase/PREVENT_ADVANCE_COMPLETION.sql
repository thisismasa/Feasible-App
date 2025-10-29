-- ============================================================================
-- PREVENT ADVANCE COMPLETION - Block Completing Sessions in Advance
-- ============================================================================
-- This prevents trainers from marking sessions as "completed" in advance
-- Can only complete sessions on the SAME DAY they are scheduled
-- ============================================================================
-- Example:
--   Today is Oct 29
--   ✅ Can complete session scheduled for Oct 29 (today)
--   ❌ Cannot complete session scheduled for Oct 30 (tomorrow)
-- ============================================================================

-- STEP 1: Create validation function
CREATE OR REPLACE FUNCTION validate_session_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_scheduled_date DATE;
  v_today_date DATE;
BEGIN
  -- Only validate when status is being changed to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Get the scheduled date (date only, no time)
    v_scheduled_date := NEW.scheduled_start::DATE;
    v_today_date := CURRENT_DATE;

    RAISE NOTICE '⏳ Attempting to complete session: scheduled=%, today=%', v_scheduled_date, v_today_date;

    -- Block if trying to complete a session scheduled for a different day
    IF v_scheduled_date != v_today_date THEN
      RAISE EXCEPTION 'Cannot complete session in advance. Session is scheduled for % but today is %. You can only complete sessions on the same day they are scheduled.',
        to_char(v_scheduled_date, 'DD Mon YYYY'),
        to_char(v_today_date, 'DD Mon YYYY');
    END IF;

    RAISE NOTICE '✅ Session completion allowed - scheduled date matches today';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_session_completion IS
  'Prevents completing sessions in advance - only allows completion on the same day as scheduled';


-- STEP 2: Create trigger on sessions table
DROP TRIGGER IF EXISTS trigger_validate_session_completion ON sessions;

CREATE TRIGGER trigger_validate_session_completion
  BEFORE UPDATE OF status ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION validate_session_completion();

COMMENT ON TRIGGER trigger_validate_session_completion ON sessions IS
  'Validates that sessions can only be marked as completed on the same day they are scheduled';


-- STEP 3: Test the trigger - Try to complete tomorrow's session (should fail)
DO $$
DECLARE
  v_session_id UUID;
  v_error_occurred BOOLEAN := FALSE;
BEGIN
  -- Create a test session for tomorrow
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    status,
    session_type,
    created_at,
    updated_at
  ) VALUES (
    'd3503cf5-60c5-4378-99fa-0e91efdd2f90'::UUID, -- Khun Boss
    '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID, -- Trainer
    '6d9641c2-0389-4f1e-ba4c-9d8689cc960a'::UUID, -- Package
    (CURRENT_DATE + INTERVAL '1 day' + INTERVAL '10 hours')::TIMESTAMPTZ,
    (CURRENT_DATE + INTERVAL '1 day' + INTERVAL '11 hours')::TIMESTAMPTZ,
    60,
    'scheduled',
    'in_person',
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  RAISE NOTICE '========== TEST 1: Try to Complete Tomorrow Session ==========';
  RAISE NOTICE 'Created test session: %', v_session_id;

  -- Try to complete it (should fail)
  BEGIN
    UPDATE sessions
    SET status = 'completed', updated_at = NOW()
    WHERE id = v_session_id;

    RAISE NOTICE '❌ WRONG: Tomorrow session was allowed to complete!';
  EXCEPTION
    WHEN OTHERS THEN
      v_error_occurred := TRUE;
      RAISE NOTICE '✅ CORRECT: Tomorrow session was BLOCKED from completion';
      RAISE NOTICE 'Error message: %', SQLERRM;
  END;

  -- Clean up test session
  DELETE FROM sessions WHERE id = v_session_id;

  IF NOT v_error_occurred THEN
    RAISE EXCEPTION 'TEST FAILED: Tomorrow session should have been blocked!';
  END IF;
END $$;


-- STEP 4: Test the trigger - Try to complete today's session (should succeed)
DO $$
DECLARE
  v_session_id UUID;
  v_success BOOLEAN := FALSE;
BEGIN
  -- Create a test session for today
  INSERT INTO sessions (
    client_id,
    trainer_id,
    package_id,
    scheduled_start,
    scheduled_end,
    duration_minutes,
    status,
    session_type,
    created_at,
    updated_at
  ) VALUES (
    'd3503cf5-60c5-4378-99fa-0e91efdd2f90'::UUID, -- Khun Boss
    '72f779ab-e255-44f6-8f27-81f17bb24921'::UUID, -- Trainer
    '6d9641c2-0389-4f1e-ba4c-9d8689cc960a'::UUID, -- Package
    (CURRENT_DATE + INTERVAL '14 hours')::TIMESTAMPTZ,
    (CURRENT_DATE + INTERVAL '15 hours')::TIMESTAMPTZ,
    60,
    'scheduled',
    'in_person',
    NOW(),
    NOW()
  ) RETURNING id INTO v_session_id;

  RAISE NOTICE '========== TEST 2: Try to Complete Today Session ==========';
  RAISE NOTICE 'Created test session: %', v_session_id;

  -- Try to complete it (should succeed)
  BEGIN
    UPDATE sessions
    SET status = 'completed', updated_at = NOW()
    WHERE id = v_session_id;

    v_success := TRUE;
    RAISE NOTICE '✅ CORRECT: Today session was ALLOWED to complete';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ WRONG: Today session was BLOCKED (should be allowed!)';
      RAISE NOTICE 'Error message: %', SQLERRM;
  END;

  -- Clean up test session
  DELETE FROM sessions WHERE id = v_session_id;

  IF NOT v_success THEN
    RAISE EXCEPTION 'TEST FAILED: Today session should have been allowed!';
  END IF;
END $$;


-- STEP 5: Show summary
SELECT
  '========================================' as message
UNION ALL SELECT '✅ COMPLETION POLICY UPDATED'
UNION ALL SELECT '========================================'
UNION ALL SELECT 'NEW RULE: Can only complete sessions on SAME DAY'
UNION ALL SELECT ''
UNION ALL SELECT 'BOOKING:'
UNION ALL SELECT '  ✅ Can book sessions in advance (tomorrow, next week, etc.)'
UNION ALL SELECT '  ✅ Calendar allows selecting future dates'
UNION ALL SELECT ''
UNION ALL SELECT 'COMPLETION:'
UNION ALL SELECT '  ✅ Can complete sessions scheduled for TODAY'
UNION ALL SELECT '  ❌ Cannot complete sessions scheduled for future dates'
UNION ALL SELECT '  ❌ Must wait until scheduled date to mark as complete'
UNION ALL SELECT ''
UNION ALL SELECT 'NEXT STEPS:'
UNION ALL SELECT '1. Restart Flutter app'
UNION ALL SELECT '2. Try booking for tomorrow - should work'
UNION ALL SELECT '3. Try completing tomorrows session - should be blocked'
UNION ALL SELECT '4. Complete today sessions - should work';
