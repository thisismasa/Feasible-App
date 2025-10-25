-- ============================================================================
-- FIX: Update trigger to work with sessions.package_id = client_packages.id
-- Purpose: Auto-decrement remaining_sessions when booking
-- ============================================================================

-- Step 1: Drop old trigger and function
DROP TRIGGER IF EXISTS auto_sync_package_sessions ON sessions CASCADE;
DROP FUNCTION IF EXISTS sync_package_remaining_sessions() CASCADE;

-- Step 2: Create NEW trigger function that works with client_packages.id
CREATE OR REPLACE FUNCTION sync_package_remaining_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- CRITICAL: sessions.package_id now stores client_packages.id (not packages.id!)

  -- When booking a new session (INSERT with status = 'scheduled')
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    UPDATE client_packages
    SET
      remaining_sessions = GREATEST(remaining_sessions - 1, 0),
      used_sessions = used_sessions + 1,
      updated_at = NOW()
    WHERE id = NEW.package_id  -- Direct match: sessions.package_id = client_packages.id
      AND status = 'active';

    RAISE NOTICE 'Session booked: Decremented package % sessions', NEW.package_id;
  END IF;

  -- When cancelling a session (UPDATE from 'scheduled' to 'cancelled')
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    UPDATE client_packages
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0),
      updated_at = NOW()
    WHERE id = NEW.package_id
      AND status = 'active';

    RAISE NOTICE 'Session cancelled: Refunded package % sessions', NEW.package_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create trigger
CREATE TRIGGER auto_sync_package_sessions
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION sync_package_remaining_sessions();

-- Step 4: Verify trigger was created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE trigger_name = 'auto_sync_package_sessions'
  ) THEN
    RAISE NOTICE '✅ Trigger auto_sync_package_sessions created successfully';
    RAISE NOTICE '✅ Will auto-update remaining_sessions on booking/cancel';
    RAISE NOTICE '✅ Works with sessions.package_id = client_packages.id';
  ELSE
    RAISE EXCEPTION '❌ Trigger was not created';
  END IF;
END $$;

-- ============================================================================
-- WHAT CHANGED:
-- ============================================================================
-- OLD (WRONG):
--   WHERE cp.package_id = NEW.package_id
--     AND cp.client_id = NEW.client_id
--
-- NEW (CORRECT):
--   WHERE id = NEW.package_id  -- Direct match to client_packages.id
--
-- This is because sessions.package_id now stores client_packages.id directly
-- ============================================================================

-- ============================================================================
-- TEST THE TRIGGER MANUALLY:
-- ============================================================================
-- After running this, try booking another session and check:
-- SELECT remaining_sessions FROM client_packages WHERE id = 'your-package-id';
-- It should decrement from current value
-- ============================================================================
