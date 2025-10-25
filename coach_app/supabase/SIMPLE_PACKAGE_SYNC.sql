-- ============================================================================
-- SIMPLE PACKAGE SYNC - Only updates sessions_remaining
-- ============================================================================
-- Works with minimal client_packages schema
-- ============================================================================

-- STEP 1: Create simple trigger to update sessions_remaining
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_sessions_remaining()
RETURNS TRIGGER AS $$
DECLARE
  v_client_package_id UUID;
BEGIN
  -- When a new session is booked (status = 'scheduled')
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    -- Find and update the client_package
    UPDATE client_packages cp
    SET
      sessions_remaining = GREATEST(sessions_remaining - 1, 0),
      sessions_scheduled = sessions_scheduled + 1,
      updated_at = NOW()
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active'
      AND cp.sessions_remaining > 0;

    RAISE NOTICE 'Session booked: sessions_remaining decreased';
  END IF;

  -- When a session is cancelled (refund the session)
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    UPDATE client_packages cp
    SET
      sessions_remaining = sessions_remaining + 1,
      sessions_scheduled = GREATEST(sessions_scheduled - 1, 0),
      updated_at = NOW()
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active';

    RAISE NOTICE 'Session cancelled: sessions_remaining increased (refund)';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS auto_sync_sessions_remaining ON sessions;

-- Create the trigger
CREATE TRIGGER auto_sync_sessions_remaining
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION sync_sessions_remaining();

-- STEP 2: Recalculate all existing packages
-- ============================================================================

DO $$
DECLARE
  v_package RECORD;
  v_scheduled INTEGER;
  v_completed INTEGER;
  v_remaining INTEGER;
  v_total INTEGER;
BEGIN
  RAISE NOTICE '🔄 Recalculating all client packages...';

  FOR v_package IN
    SELECT
      cp.id,
      cp.client_id,
      cp.package_id,
      p.sessions as total
    FROM client_packages cp
    JOIN packages p ON cp.package_id = p.id
    JOIN trainer_clients tc ON tc.client_id = cp.client_id
    WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
      AND cp.status = 'active'
  LOOP
    v_total := v_package.total;

    -- Count scheduled sessions
    SELECT COUNT(*) INTO v_scheduled
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'scheduled';

    -- Count completed sessions
    SELECT COUNT(*) INTO v_completed
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'completed';

    -- Calculate remaining
    v_remaining := v_total - v_scheduled - v_completed;

    -- Update
    UPDATE client_packages
    SET
      sessions_remaining = GREATEST(v_remaining, 0),
      sessions_scheduled = v_scheduled,
      updated_at = NOW()
    WHERE id = v_package.id;

    RAISE NOTICE 'Package %: total=%, scheduled=%, completed=%, remaining=%',
      v_package.id, v_total, v_scheduled, v_completed, v_remaining;
  END LOOP;
END $$;

-- STEP 3: Verify
-- ============================================================================

SELECT
  '✅ Sync Complete' as status,
  u.full_name as client_name,
  p.name as package_name,
  p.sessions as total,
  cp.sessions_remaining,
  cp.sessions_scheduled,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.package_id = p.id
     AND s.client_id = cp.client_id
     AND s.status = 'scheduled') as actual_scheduled
FROM client_packages cp
JOIN packages p ON cp.package_id = p.id
JOIN users u ON cp.client_id = u.id
JOIN trainer_clients tc ON tc.client_id = cp.client_id
WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  AND cp.status = 'active';

SELECT '✅ Trigger installed: auto_sync_sessions_remaining' as message;
