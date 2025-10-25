-- ============================================================================
-- COMPLETE BOOKING WORKFLOW WITH REAL-TIME PACKAGE SYNC
-- ============================================================================
-- User Story:
-- 1. Client has 10 sessions
-- 2. Client books session → pending status → 10 sessions (held but not deducted yet)
-- 3. After workout completion → confirm session → 9 sessions
-- 4. If cancelled before workout → refund → back to 10 sessions

-- Current trigger only handles 'scheduled' status
-- We need to update it to handle the full workflow

-- ============================================================================
-- STEP 1: Check current package status
-- ============================================================================

SELECT
  cp.id,
  c.full_name as client_name,
  p.name as package_name,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.used_sessions,
  cp.status,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.client_id = cp.client_id
   AND s.package_id = cp.package_id
   AND s.status = 'scheduled') as pending_sessions,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.client_id = cp.client_id
   AND s.package_id = cp.package_id
   AND s.status = 'completed') as completed_sessions
FROM client_packages cp
JOIN users c ON c.id = cp.client_id
JOIN packages p ON p.id = cp.package_id
WHERE cp.client_id = 'db18b246-63dc-4627-91b3-6bb6bb8a5a95'
  AND cp.status = 'active';

-- ============================================================================
-- STEP 2: Enhanced trigger for full booking lifecycle
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_package_remaining_sessions()
RETURNS TRIGGER AS $$
DECLARE
  v_client_package_id UUID;
BEGIN
  -- Find the client_package record
  SELECT cp.id INTO v_client_package_id
  FROM client_packages cp
  WHERE cp.package_id = NEW.package_id
    AND cp.client_id = NEW.client_id
    AND cp.status = 'active'
  LIMIT 1;

  IF v_client_package_id IS NULL THEN
    RAISE NOTICE '⚠️ No active package found for client % and package %', NEW.client_id, NEW.package_id;
    RETURN NEW;
  END IF;

  -- WORKFLOW 1: New booking (status = 'scheduled')
  -- Immediately deduct from remaining_sessions and add to used_sessions
  IF (TG_OP = 'INSERT' AND NEW.status = 'scheduled') THEN
    UPDATE client_packages
    SET
      remaining_sessions = GREATEST(remaining_sessions - 1, 0),
      used_sessions = used_sessions + 1
    WHERE id = v_client_package_id
      AND remaining_sessions > 0;

    RAISE NOTICE '✅ Session booked: remaining_sessions decreased, used_sessions increased';
    RAISE NOTICE '📊 Package ID: %, Remaining: %', v_client_package_id,
                 (SELECT remaining_sessions FROM client_packages WHERE id = v_client_package_id);
  END IF;

  -- WORKFLOW 2: Session completed (scheduled → completed)
  -- Sessions already deducted, no change needed
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'completed') THEN
    RAISE NOTICE '✅ Session completed: no changes needed (already deducted)';
  END IF;

  -- WORKFLOW 3: Session cancelled before completion (scheduled → cancelled)
  -- Refund the session back to remaining_sessions
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
    UPDATE client_packages
    SET
      remaining_sessions = remaining_sessions + 1,
      used_sessions = GREATEST(used_sessions - 1, 0)
    WHERE id = v_client_package_id;

    RAISE NOTICE '✅ Session cancelled: remaining_sessions refunded';
    RAISE NOTICE '📊 Package ID: %, Remaining: %', v_client_package_id,
                 (SELECT remaining_sessions FROM client_packages WHERE id = v_client_package_id);
  END IF;

  -- WORKFLOW 4: No-show (scheduled → no_show)
  -- Don't refund - session was wasted
  IF (TG_OP = 'UPDATE' AND OLD.status = 'scheduled' AND NEW.status = 'no_show') THEN
    RAISE NOTICE '❌ Session no-show: no refund (session already deducted)';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger and create new one
DROP TRIGGER IF EXISTS auto_sync_package_sessions ON sessions;

CREATE TRIGGER auto_sync_package_sessions
  AFTER INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION sync_package_remaining_sessions();

-- ============================================================================
-- STEP 3: Recalculate all packages to match actual state
-- ============================================================================

DO $$
DECLARE
  v_package RECORD;
  v_scheduled INTEGER;
  v_completed INTEGER;
  v_used INTEGER;
  v_remaining INTEGER;
BEGIN
  FOR v_package IN
    SELECT cp.id, cp.client_id, cp.package_id, cp.total_sessions
    FROM client_packages cp
    WHERE cp.status = 'active'
  LOOP
    -- Count scheduled (booked but not completed)
    SELECT COUNT(*) INTO v_scheduled
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'scheduled';

    -- Count completed
    SELECT COUNT(*) INTO v_completed
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status = 'completed';

    -- Count no-shows (also deducted)
    SELECT COUNT(*) INTO v_used
    FROM sessions
    WHERE client_id = v_package.client_id
      AND package_id = v_package.package_id
      AND status IN ('scheduled', 'completed', 'no_show');

    v_remaining := GREATEST(v_package.total_sessions - v_used, 0);

    UPDATE client_packages
    SET
      used_sessions = v_used,
      remaining_sessions = v_remaining
    WHERE id = v_package.id;

    RAISE NOTICE 'Package %: Total=%, Used=%, Remaining=%',
                 v_package.id, v_package.total_sessions, v_used, v_remaining;
  END LOOP;
END $$;

-- ============================================================================
-- STEP 4: Verify the sync
-- ============================================================================

SELECT
  '✅ Enhanced booking workflow installed' as status,
  'Workflow: Book → Deduct immediately → Cancel → Refund' as flow;

-- Show Nuttapon's package status after sync
SELECT
  c.full_name as client,
  p.name as package,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.client_id = cp.client_id
   AND s.package_id = cp.package_id
   AND s.status = 'scheduled') as scheduled_count,
  (SELECT COUNT(*) FROM sessions s
   WHERE s.client_id = cp.client_id
   AND s.package_id = cp.package_id
   AND s.status = 'completed') as completed_count
FROM client_packages cp
JOIN users c ON c.id = cp.client_id
JOIN packages p ON p.id = cp.package_id
WHERE cp.client_id = 'db18b246-63dc-4627-91b3-6bb6bb8a5a95'
  AND cp.status = 'active';
