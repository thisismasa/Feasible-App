-- ============================================================================
-- FINAL PACKAGE SYNC - Correct for YOUR actual schema
-- ============================================================================
-- Uses: remaining_sessions, used_sessions, total_sessions
-- ============================================================================

-- STEP 1: Create trigger to auto-update remaining_sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_package_remaining_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- When a new session is booked (status = 'scheduled')
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    UPDATE client_packages cp
    SET
      remaining_sessions = GREATEST(remaining_sessions - 1, 0),
      used_sessions = used_sessions + 1
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active'
      AND cp.remaining_sessions > 0;

    RAISE NOTICE '✅ Session booked: remaining_sessions decreased, used_sessions increased';
  END IF;

  -- When a session is cancelled (refund)
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    UPDATE client_packages cp
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0)
    WHERE cp.package_id = NEW.package_id
      AND cp.client_id = NEW.client_id
      AND cp.status = 'active';

    RAISE NOTICE '✅ Session cancelled: remaining_sessions increased (refund), used_sessions decreased';
  END IF;

  -- When a session is completed (just for logging, counts already adjusted)
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'completed') THEN
    RAISE NOTICE '✅ Session completed (no package changes needed)';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS auto_sync_package_sessions ON sessions;

-- Create the trigger
CREATE TRIGGER auto_sync_package_sessions
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION sync_package_remaining_sessions();

COMMENT ON FUNCTION sync_package_remaining_sessions IS 'Auto-sync remaining_sessions and used_sessions when sessions are booked/cancelled';

-- STEP 2: Recalculate all existing packages
-- ============================================================================

DO $$
DECLARE
  v_package RECORD;
  v_scheduled INTEGER;
  v_completed INTEGER;
  v_used INTEGER;
  v_remaining INTEGER;
BEGIN
  RAISE NOTICE '🔄 Recalculating all client packages...';

  FOR v_package IN
    SELECT
      cp.id,
      cp.client_id,
      cp.package_id,
      cp.total_sessions
    FROM client_packages cp
    JOIN trainer_clients tc ON tc.client_id = cp.client_id
    WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
      AND cp.status = 'active'
  LOOP
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

    -- Calculate used and remaining
    v_used := v_scheduled + v_completed;
    v_remaining := v_package.total_sessions - v_used;

    -- Update package
    UPDATE client_packages
    SET
      used_sessions = v_used,
      remaining_sessions = GREATEST(v_remaining, 0)
    WHERE id = v_package.id;

    RAISE NOTICE 'Package %: total=%, scheduled=%, completed=%, used=%, remaining=%',
      v_package.id, v_package.total_sessions, v_scheduled, v_completed, v_used, v_remaining;
  END LOOP;

  RAISE NOTICE '✅ All packages recalculated!';
END $$;

-- STEP 3: Verify the sync
-- ============================================================================

SELECT
  '✅ Package Sync Complete' as status,
  u.full_name as client_name,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.package_id = cp.package_id
     AND s.client_id = cp.client_id
     AND s.status IN ('scheduled', 'completed')) as actual_used_sessions
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
JOIN trainer_clients tc ON tc.client_id = cp.client_id
WHERE tc.trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  AND cp.status = 'active'
ORDER BY u.full_name;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '🎉 Package Sync Installed!' as message,
       'Trigger: auto_sync_package_sessions' as trigger_name,
       'Updates: remaining_sessions & used_sessions' as what_it_does,
       'On: INSERT & UPDATE of sessions' as when_it_runs;
