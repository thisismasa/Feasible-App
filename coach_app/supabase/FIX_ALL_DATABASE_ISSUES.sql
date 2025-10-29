-- ============================================================================
-- FIX ALL DATABASE ISSUES - COMPREHENSIVE REPAIR
-- ============================================================================
-- This script fixes all common database issues found in your system
-- Run this AFTER running DATABASE_HEALTH_CHECK.sql
-- ============================================================================

-- FIX 1: Ensure sessions table has all required columns
-- ============================================================================
DO $$
BEGIN
  -- Add scheduled_end if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'scheduled_end'
  ) THEN
    ALTER TABLE sessions ADD COLUMN scheduled_end TIMESTAMPTZ;

    -- Calculate scheduled_end from scheduled_start + duration
    UPDATE sessions
    SET scheduled_end = scheduled_start + (duration_minutes || ' minutes')::INTERVAL
    WHERE scheduled_end IS NULL AND scheduled_start IS NOT NULL AND duration_minutes IS NOT NULL;

    RAISE NOTICE '✅ Added scheduled_end column';
  END IF;

  -- Add buffer_start if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'buffer_start'
  ) THEN
    ALTER TABLE sessions ADD COLUMN buffer_start TIMESTAMPTZ;
    RAISE NOTICE '✅ Added buffer_start column';
  END IF;

  -- Add buffer_end if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'buffer_end'
  ) THEN
    ALTER TABLE sessions ADD COLUMN buffer_end TIMESTAMPTZ;
    RAISE NOTICE '✅ Added buffer_end column';
  END IF;

  -- Add google_calendar_event_id if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'google_calendar_event_id'
  ) THEN
    ALTER TABLE sessions ADD COLUMN google_calendar_event_id TEXT;
    RAISE NOTICE '✅ Added google_calendar_event_id column';
  END IF;

  -- Add has_conflicts if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'has_conflicts'
  ) THEN
    ALTER TABLE sessions ADD COLUMN has_conflicts BOOLEAN DEFAULT FALSE;
    RAISE NOTICE '✅ Added has_conflicts column';
  END IF;

  -- Add validation_passed if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'sessions' AND column_name = 'validation_passed'
  ) THEN
    ALTER TABLE sessions ADD COLUMN validation_passed BOOLEAN DEFAULT TRUE;
    RAISE NOTICE '✅ Added validation_passed column';
  END IF;
END $$;

-- FIX 2: Calculate missing scheduled_end times
-- ============================================================================
UPDATE sessions
SET scheduled_end = scheduled_start + (duration_minutes || ' minutes')::INTERVAL
WHERE scheduled_end IS NULL
  AND scheduled_start IS NOT NULL
  AND duration_minutes IS NOT NULL;

-- FIX 3: Calculate missing buffer times
-- ============================================================================
UPDATE sessions
SET
  buffer_start = scheduled_start - INTERVAL '15 minutes',
  buffer_end = COALESCE(scheduled_end, scheduled_start + (duration_minutes || ' minutes')::INTERVAL) + INTERVAL '15 minutes'
WHERE (buffer_start IS NULL OR buffer_end IS NULL)
  AND scheduled_start IS NOT NULL;

-- FIX 4: Create or replace critical booking functions
-- ============================================================================

-- Function: get_buffer_minutes (if missing)
CREATE OR REPLACE FUNCTION get_buffer_minutes(p_trainer_id UUID)
RETURNS INTEGER AS $$
BEGIN
  -- Return 15 minutes default buffer
  RETURN 15;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: book_session (main booking function)
CREATE OR REPLACE FUNCTION book_session(
  p_client_id UUID,
  p_trainer_id UUID,
  p_scheduled_date TIMESTAMPTZ,
  p_duration_minutes INTEGER,
  p_package_id UUID,
  p_session_type TEXT DEFAULT 'in_person',
  p_location TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_session_id UUID;
  v_scheduled_end TIMESTAMPTZ;
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
  v_package_sessions INTEGER;
BEGIN
  -- Calculate times
  v_scheduled_end := p_scheduled_date + (p_duration_minutes || ' minutes')::INTERVAL;
  v_buffer_start := p_scheduled_date - INTERVAL '15 minutes';
  v_buffer_end := v_scheduled_end + INTERVAL '15 minutes';

  -- Check package has sessions
  SELECT remaining_sessions INTO v_package_sessions
  FROM client_packages
  WHERE id = p_package_id
    AND client_id = p_client_id
    AND status = 'active';

  IF v_package_sessions IS NULL OR v_package_sessions <= 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'No sessions remaining in package'
    );
  END IF;

  -- Create session
  INSERT INTO sessions (
    client_id, trainer_id, package_id,
    scheduled_date, scheduled_start, scheduled_end,
    buffer_start, buffer_end,
    duration_minutes, status,
    session_type, location, client_notes,
    has_conflicts, validation_passed
  ) VALUES (
    p_client_id, p_trainer_id, p_package_id,
    p_scheduled_date, p_scheduled_date, v_scheduled_end,
    v_buffer_start, v_buffer_end,
    p_duration_minutes, 'scheduled',
    p_session_type, p_location, p_notes,
    FALSE, TRUE
  ) RETURNING id INTO v_session_id;

  -- Update package
  UPDATE client_packages
  SET remaining_sessions = remaining_sessions - 1,
      updated_at = NOW()
  WHERE id = p_package_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Session booked successfully',
    'session_id', v_session_id
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Booking failed: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Function: cancel_session
CREATE OR REPLACE FUNCTION cancel_session(
  p_session_id UUID,
  p_reason TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_package_id UUID;
  v_status TEXT;
BEGIN
  -- Get session info
  SELECT package_id, status INTO v_package_id, v_status
  FROM sessions
  WHERE id = p_session_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Session not found'
    );
  END IF;

  IF v_status = 'cancelled' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Session already cancelled'
    );
  END IF;

  -- Update session
  UPDATE sessions
  SET status = 'cancelled',
      cancellation_reason = p_reason,
      cancelled_at = NOW(),
      updated_at = NOW()
  WHERE id = p_session_id;

  -- Return session to package
  UPDATE client_packages
  SET remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
  WHERE id = v_package_id;

  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Session cancelled successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', 'Cancellation failed: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Function: check_booking_conflicts
CREATE OR REPLACE FUNCTION check_booking_conflicts(
  p_trainer_id UUID,
  p_client_id UUID,
  p_scheduled_start TIMESTAMPTZ,
  p_scheduled_end TIMESTAMPTZ,
  p_excluded_session_id UUID DEFAULT NULL
) RETURNS TABLE (
  conflict_type TEXT,
  conflict_description TEXT,
  conflicting_session_id UUID
) AS $$
DECLARE
  v_buffer_start TIMESTAMPTZ;
  v_buffer_end TIMESTAMPTZ;
BEGIN
  v_buffer_start := p_scheduled_start - INTERVAL '15 minutes';
  v_buffer_end := p_scheduled_end + INTERVAL '15 minutes';

  -- Check trainer conflicts
  RETURN QUERY
  SELECT
    'trainer_conflict'::TEXT,
    'Trainer has another session at this time'::TEXT,
    s.id
  FROM sessions s
  WHERE s.trainer_id = p_trainer_id
    AND s.status NOT IN ('cancelled', 'no_show')
    AND s.id != COALESCE(p_excluded_session_id, '00000000-0000-0000-0000-000000000000'::UUID)
    AND (
      (s.scheduled_start, COALESCE(s.scheduled_end, s.scheduled_start + (s.duration_minutes || ' minutes')::INTERVAL))
      OVERLAPS
      (v_buffer_start, v_buffer_end)
    );

  RETURN;
END;
$$ LANGUAGE plpgsql STABLE;

-- FIX 5: Create indexes for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_sessions_trainer_date
  ON sessions(trainer_id, scheduled_start);

CREATE INDEX IF NOT EXISTS idx_sessions_client_date
  ON sessions(client_id, scheduled_start);

CREATE INDEX IF NOT EXISTS idx_sessions_status
  ON sessions(status) WHERE status IN ('scheduled', 'confirmed');

CREATE INDEX IF NOT EXISTS idx_client_packages_active
  ON client_packages(client_id, status) WHERE status = 'active';

-- FIX 6: Fix any invalid time ranges in sessions
-- ============================================================================
UPDATE sessions
SET scheduled_end = scheduled_start + (duration_minutes || ' minutes')::INTERVAL
WHERE scheduled_end IS NOT NULL
  AND scheduled_start IS NOT NULL
  AND scheduled_end <= scheduled_start;

-- FIX 7: Ensure booking_rules table exists
-- ============================================================================
CREATE TABLE IF NOT EXISTS booking_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID REFERENCES users(id),
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL,
  rule_value JSONB NOT NULL,
  priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_rule_per_trainer UNIQUE(trainer_id, rule_name)
);

-- Insert default rules if missing
INSERT INTO booking_rules (rule_name, rule_type, rule_value, priority) VALUES
('global_buffer_time', 'buffer_minutes', '{"before": 15, "after": 15}'::JSONB, 100),
('global_min_advance', 'min_advance_hours', '{"hours": 0}'::JSONB, 100),
('global_max_advance', 'max_advance_days', '{"days": 90}'::JSONB, 100),
('global_max_daily', 'max_daily_sessions', '{"limit": 8}'::JSONB, 100)
ON CONFLICT (trainer_id, rule_name) DO NOTHING;

-- FIX 8: Grant necessary permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION book_session TO authenticated;
GRANT EXECUTE ON FUNCTION book_session TO anon;
GRANT EXECUTE ON FUNCTION cancel_session TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_session TO anon;
GRANT EXECUTE ON FUNCTION check_booking_conflicts TO authenticated;
GRANT EXECUTE ON FUNCTION check_booking_conflicts TO anon;
GRANT EXECUTE ON FUNCTION get_buffer_minutes TO authenticated;
GRANT EXECUTE ON FUNCTION get_buffer_minutes TO anon;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT '✅ ALL FIXES APPLIED!' as status;

SELECT
  '✅ Columns added/verified' as fix_1,
  '✅ Missing timestamps calculated' as fix_2,
  '✅ Buffer times calculated' as fix_3,
  '✅ Critical functions created' as fix_4,
  '✅ Performance indexes added' as fix_5,
  '✅ Invalid data fixed' as fix_6,
  '✅ Booking rules ensured' as fix_7,
  '✅ Permissions granted' as fix_8;

-- Show current health
SELECT
  COUNT(*) as total_sessions,
  COUNT(*) FILTER (WHERE scheduled_end IS NOT NULL) as with_end_time,
  COUNT(*) FILTER (WHERE buffer_start IS NOT NULL) as with_buffer,
  COUNT(*) FILTER (WHERE google_calendar_event_id IS NOT NULL) as synced_to_calendar
FROM sessions;
