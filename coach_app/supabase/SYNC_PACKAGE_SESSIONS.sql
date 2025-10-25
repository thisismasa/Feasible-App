-- ============================================================================
-- SYNC PACKAGE REMAINING SESSIONS WITH BOOKINGS
-- ============================================================================
-- Ensures package remaining_sessions accurately reflects booked sessions
-- ============================================================================

-- STEP 1: Add trigger to automatically update package remaining_sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION update_package_sessions_on_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- When a new session is booked (status = 'scheduled')
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    -- Decrement remaining_sessions
    UPDATE packages
    SET
      remaining_sessions = GREATEST(remaining_sessions - 1, 0),
      updated_at = NOW()
    WHERE id = NEW.package_id
      AND remaining_sessions > 0;

    RAISE NOTICE 'Package % decremented: 1 session used', NEW.package_id;
  END IF;

  -- When a session is cancelled
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    -- Increment remaining_sessions (refund the session)
    UPDATE packages
    SET
      remaining_sessions = remaining_sessions + 1,
      updated_at = NOW()
    WHERE id = NEW.package_id;

    RAISE NOTICE 'Package % incremented: 1 session refunded', NEW.package_id;
  END IF;

  -- When a session is completed (no refund, just tracking)
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'completed') THEN
    RAISE NOTICE 'Package %: Session completed', NEW.package_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS sync_package_sessions_on_booking ON sessions;

-- Create the trigger
CREATE TRIGGER sync_package_sessions_on_booking
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_package_sessions_on_booking();

COMMENT ON FUNCTION update_package_sessions_on_booking IS 'Automatically sync package remaining_sessions when sessions are booked/cancelled';

-- STEP 2: Function to recalculate remaining sessions for a package
-- ============================================================================

CREATE OR REPLACE FUNCTION recalculate_package_sessions(p_package_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_total_sessions INTEGER;
  v_scheduled_count INTEGER;
  v_completed_count INTEGER;
  v_new_remaining INTEGER;
BEGIN
  -- Get package total sessions
  SELECT sessions INTO v_total_sessions
  FROM packages
  WHERE id = p_package_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Package not found'
    );
  END IF;

  -- Count scheduled sessions
  SELECT COUNT(*) INTO v_scheduled_count
  FROM sessions
  WHERE package_id = p_package_id
    AND status = 'scheduled';

  -- Count completed sessions
  SELECT COUNT(*) INTO v_completed_count
  FROM sessions
  WHERE package_id = p_package_id
    AND status = 'completed';

  -- Calculate remaining
  v_new_remaining := v_total_sessions - v_scheduled_count - v_completed_count;

  -- Update package
  UPDATE packages
  SET remaining_sessions = GREATEST(v_new_remaining, 0)
  WHERE id = p_package_id;

  RETURN jsonb_build_object(
    'success', true,
    'package_id', p_package_id,
    'total_sessions', v_total_sessions,
    'scheduled_sessions', v_scheduled_count,
    'completed_sessions', v_completed_count,
    'remaining_sessions', v_new_remaining
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION recalculate_package_sessions IS 'Manually recalculate remaining sessions for a package';

-- STEP 3: Recalculate all packages for the trainer
-- ============================================================================

DO $$
DECLARE
  v_package RECORD;
  v_result JSONB;
BEGIN
  FOR v_package IN
    SELECT DISTINCT p.id
    FROM packages p
    JOIN client_packages cp ON cp.package_id = p.id
    JOIN trainer_clients tc ON tc.client_id = cp.client_id
    WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  LOOP
    v_result := recalculate_package_sessions(v_package.id);
    RAISE NOTICE 'Recalculated package %: %', v_package.id, v_result;
  END LOOP;
END $$;

-- STEP 4: Verify the sync
-- ============================================================================

SELECT
  '✅ Package sessions synced' as status,
  p.id as package_id,
  p.name as package_name,
  p.sessions as total_sessions,
  p.remaining_sessions,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'scheduled') as scheduled_count,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND status = 'completed') as completed_count
FROM packages p
JOIN client_packages cp ON cp.package_id = p.id
JOIN trainer_clients tc ON tc.client_id = cp.client_id
WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921';

-- Grant permissions
GRANT EXECUTE ON FUNCTION recalculate_package_sessions TO authenticated;
