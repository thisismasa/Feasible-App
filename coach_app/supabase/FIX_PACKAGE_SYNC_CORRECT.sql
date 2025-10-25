-- ============================================================================
-- FIX PACKAGE SYNC - CORRECT VERSION for client_packages table
-- ============================================================================
-- This works with the ACTUAL schema: client_packages.sessions_remaining
-- ============================================================================

-- STEP 1: Create trigger to auto-update sessions_remaining in client_packages
-- ============================================================================

CREATE OR REPLACE FUNCTION update_client_package_sessions_on_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_client_package_id UUID;
BEGIN
  -- When a new session is booked (status = 'scheduled')
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    -- Find the client_package record
    SELECT cp.id INTO v_client_package_id
    FROM client_packages cp
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active'
    LIMIT 1;

    IF v_client_package_id IS NOT NULL THEN
      -- Decrement sessions_remaining and increment sessions_scheduled
      UPDATE client_packages
      SET
        sessions_remaining = GREATEST(sessions_remaining - 1, 0),
        sessions_scheduled = sessions_scheduled + 1,
        updated_at = NOW()
      WHERE id = v_client_package_id
        AND sessions_remaining > 0;

      RAISE NOTICE 'Client Package %: 1 session booked (remaining decreased)', v_client_package_id;
    END IF;
  END IF;

  -- When a session is cancelled
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    -- Find the client_package record
    SELECT cp.id INTO v_client_package_id
    FROM client_packages cp
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active'
    LIMIT 1;

    IF v_client_package_id IS NOT NULL THEN
      -- Increment sessions_remaining (refund) and decrement sessions_scheduled
      UPDATE client_packages
      SET
        sessions_remaining = sessions_remaining + 1,
        sessions_scheduled = GREATEST(sessions_scheduled - 1, 0),
        updated_at = NOW()
      WHERE id = v_client_package_id;

      RAISE NOTICE 'Client Package %: 1 session refunded (remaining increased)', v_client_package_id;
    END IF;
  END IF;

  -- When a session is completed
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'completed') THEN
    -- Find the client_package record
    SELECT cp.id INTO v_client_package_id
    FROM client_packages cp
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active'
    LIMIT 1;

    IF v_client_package_id IS NOT NULL THEN
      -- Just update the scheduled count (already decremented from remaining when booked)
      UPDATE client_packages
      SET
        sessions_scheduled = GREATEST(sessions_scheduled - 1, 0),
        sessions_completed = sessions_completed + 1,
        updated_at = NOW()
      WHERE id = v_client_package_id;

      RAISE NOTICE 'Client Package %: 1 session completed', v_client_package_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS sync_client_package_on_booking ON sessions;

-- Create the trigger
CREATE TRIGGER sync_client_package_on_booking
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_client_package_sessions_on_booking();

COMMENT ON FUNCTION update_client_package_sessions_on_booking IS 'Auto-sync client_packages.sessions_remaining when sessions are booked/cancelled/completed';

-- STEP 2: Function to recalculate sessions for a client_package
-- ============================================================================

CREATE OR REPLACE FUNCTION recalculate_client_package_sessions(p_client_package_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_client_package RECORD;
  v_scheduled_count INTEGER;
  v_completed_count INTEGER;
  v_new_remaining INTEGER;
  v_package_total INTEGER;
BEGIN
  -- Get client_package details
  SELECT
    cp.id,
    cp.client_id,
    cp.package_id,
    p.sessions as package_total
  INTO v_client_package
  FROM client_packages cp
  JOIN packages p ON cp.package_id = p.id
  WHERE cp.id = p_client_package_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Client package not found'
    );
  END IF;

  v_package_total := v_client_package.package_total;

  -- Count scheduled sessions for this client + package
  SELECT COUNT(*) INTO v_scheduled_count
  FROM sessions
  WHERE client_id = v_client_package.client_id
    AND package_id = v_client_package.package_id
    AND status = 'scheduled';

  -- Count completed sessions
  SELECT COUNT(*) INTO v_completed_count
  FROM sessions
  WHERE client_id = v_client_package.client_id
    AND package_id = v_client_package.package_id
    AND status = 'completed';

  -- Calculate remaining: total - scheduled - completed
  v_new_remaining := v_package_total - v_scheduled_count - v_completed_count;

  -- Update client_package
  UPDATE client_packages
  SET
    sessions_remaining = GREATEST(v_new_remaining, 0),
    sessions_scheduled = v_scheduled_count,
    sessions_completed = v_completed_count,
    updated_at = NOW()
  WHERE id = p_client_package_id;

  RETURN jsonb_build_object(
    'success', true,
    'client_package_id', p_client_package_id,
    'package_total', v_package_total,
    'scheduled', v_scheduled_count,
    'completed', v_completed_count,
    'remaining', v_new_remaining
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION recalculate_client_package_sessions IS 'Manually recalculate sessions for a client_package';

-- STEP 3: Recalculate all client_packages for the trainer
-- ============================================================================

DO $$
DECLARE
  v_client_package RECORD;
  v_result JSONB;
BEGIN
  RAISE NOTICE '🔄 Recalculating all client packages...';

  FOR v_client_package IN
    SELECT DISTINCT cp.id
    FROM client_packages cp
    JOIN trainer_clients tc ON tc.client_id = cp.client_id
    WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
      AND cp.status = 'active'
  LOOP
    v_result := recalculate_client_package_sessions(v_client_package.id);
    RAISE NOTICE 'Recalculated: %', v_result;
  END LOOP;
END $$;

-- STEP 4: Verify the sync
-- ============================================================================

SELECT
  '✅ Client Packages Synced' as status,
  cp.id as client_package_id,
  u.full_name as client_name,
  p.name as package_name,
  p.sessions as total_sessions,
  cp.sessions_remaining,
  cp.sessions_scheduled,
  cp.sessions_completed,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND client_id = cp.client_id AND status = 'scheduled') as actual_scheduled,
  (SELECT COUNT(*) FROM sessions WHERE package_id = p.id AND client_id = cp.client_id AND status = 'completed') as actual_completed
FROM client_packages cp
JOIN packages p ON cp.package_id = p.id
JOIN users u ON cp.client_id = u.id
JOIN trainer_clients tc ON tc.client_id = cp.client_id
WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  AND cp.status = 'active'
ORDER BY u.full_name, p.name;

-- Grant permissions
GRANT EXECUTE ON FUNCTION recalculate_client_package_sessions TO authenticated;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Package Sync Fixed!' as message,
       'Trigger: sync_client_package_on_booking' as trigger_name,
       'Target: client_packages.sessions_remaining' as target_column,
       'Auto-updates on: INSERT, UPDATE' as auto_updates;
