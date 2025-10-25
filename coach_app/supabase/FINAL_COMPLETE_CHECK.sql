-- ============================================================================
-- FINAL COMPLETE CHECK - Based on Investigation Results
-- ============================================================================
-- Active Package ID: 2c495497-2ba3-4a87-8e36-3bf0a8bcfbce
-- This package has all 7+ sessions
-- ============================================================================

-- ============================================================================
-- PART 1: Current State of Active Package
-- ============================================================================

SELECT '=== ACTIVE PACKAGE CURRENT STATE ===' as section;

SELECT
  cp.id as package_id,
  c.full_name as client_name,
  cp.package_name,
  cp.status,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked,
  CASE
    WHEN cp.used_sessions = (
      SELECT COUNT(*)
      FROM sessions s
      WHERE s.package_id = cp.id
        AND s.status IN ('scheduled', 'confirmed')
    ) THEN '✅ IN SYNC'
    ELSE '⚠️ OUT OF SYNC'
  END as sync_status,
  CASE
    WHEN cp.used_sessions = (
      SELECT COUNT(*)
      FROM sessions s
      WHERE s.package_id = cp.id
        AND s.status IN ('scheduled', 'confirmed')
    ) THEN 'No action needed'
    ELSE 'Run PART 5 to sync'
  END as action_needed
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- PART 2: List All Sessions for This Package
-- ============================================================================

SELECT '=== ALL SESSIONS FOR THIS PACKAGE ===' as section;

SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.session_type,
  s.created_at,
  CASE
    WHEN s.scheduled_start > NOW() THEN '📅 Future session'
    WHEN s.scheduled_start::date = NOW()::date THEN '📅 Today'
    ELSE '📅 Past session'
  END as timing
FROM sessions s
WHERE s.package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
  AND s.status IN ('scheduled', 'confirmed')
ORDER BY s.scheduled_start;

-- ============================================================================
-- PART 3: Check Trigger Status
-- ============================================================================

SELECT '=== TRIGGER STATUS ===' as section;

-- Check trigger exists and is enabled
SELECT
  trigger_name,
  event_object_table,
  event_manipulation,
  action_timing,
  action_statement,
  '✅ ACTIVE' as status
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions'
  AND event_object_schema = 'public';

-- Check trigger function
SELECT
  '✅ Trigger function exists' as status
FROM pg_proc
WHERE proname = 'sync_package_remaining_sessions'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- PART 4: UI Data Availability Check
-- ============================================================================

SELECT '=== UI DATA AVAILABILITY ===' as section;

-- Check what UI will see from trainer_upcoming_sessions view
SELECT
  COUNT(*) as total_sessions_in_view,
  COUNT(*) FILTER (WHERE scheduled_start > NOW()) as future_sessions,
  COUNT(*) FILTER (WHERE scheduled_start::date = NOW()::date) as today_sessions,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ UI will show data'
    ELSE '❌ UI will show empty'
  END as ui_status
FROM trainer_upcoming_sessions
WHERE session_id IN (
  SELECT id FROM sessions
  WHERE package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
);

-- Show what specific data UI will display
SELECT
  session_id,
  client_name,
  scheduled_start,
  scheduled_end,
  status,
  package_name,
  remaining_sessions,
  '✅ Will appear in UI' as ui_visibility
FROM trainer_upcoming_sessions
WHERE session_id IN (
  SELECT id FROM sessions
  WHERE package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
)
ORDER BY scheduled_start
LIMIT 10;

-- ============================================================================
-- PART 5: SYNC THE ACTIVE PACKAGE (Uncomment to run)
-- ============================================================================
-- This will update the package counts to match the actual booked sessions
-- Only run if PART 1 shows "OUT OF SYNC"
-- ============================================================================

/*
DO $$
DECLARE
  v_package_id UUID := '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';
  v_actual_count INTEGER;
  v_total_sessions INTEGER;
BEGIN
  -- Count actual sessions
  SELECT COUNT(*)
  INTO v_actual_count
  FROM sessions s
  WHERE s.package_id = v_package_id
    AND s.status IN ('scheduled', 'confirmed');

  -- Get total sessions
  SELECT total_sessions
  INTO v_total_sessions
  FROM client_packages
  WHERE id = v_package_id;

  -- Update package counts
  UPDATE client_packages
  SET
    used_sessions = v_actual_count,
    remaining_sessions = GREATEST(v_total_sessions - v_actual_count, 0),
    updated_at = NOW()
  WHERE id = v_package_id;

  RAISE NOTICE '✅ Synced package: %', v_package_id;
  RAISE NOTICE '   Used sessions: %', v_actual_count;
  RAISE NOTICE '   Remaining sessions: %', GREATEST(v_total_sessions - v_actual_count, 0);
END $$;
*/

-- ============================================================================
-- PART 6: Verify Sync Worked (Run after PART 5)
-- ============================================================================

SELECT '=== VERIFY SYNC RESULT ===' as section;

SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked,
  CASE
    WHEN cp.used_sessions = (
      SELECT COUNT(*)
      FROM sessions s
      WHERE s.package_id = cp.id
        AND s.status IN ('scheduled', 'confirmed')
    ) THEN '✅ IN SYNC - Perfect!'
    ELSE '❌ STILL OUT OF SYNC - Check trigger'
  END as final_status
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- PART 7: Prepare for New Booking Test
-- ============================================================================

SELECT '=== BEFORE NEW BOOKING TEST ===' as section;

-- Record state before booking new session
SELECT
  'RECORD THESE VALUES BEFORE BOOKING:' as instruction,
  cp.used_sessions as current_used,
  cp.remaining_sessions as current_remaining,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as current_actual
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- Show what to expect after booking
SELECT
  'AFTER BOOKING ONE NEW SESSION, EXPECT:' as instruction,
  cp.used_sessions + 1 as expected_used,
  GREATEST(cp.remaining_sessions - 1, 0) as expected_remaining,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) + 1 as expected_actual,
  '⚠️ Trigger must fire to see these changes!' as important_note
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

SELECT '=== FINAL SUMMARY ===' as section;

WITH package_status AS (
  SELECT
    cp.id,
    cp.total_sessions,
    cp.used_sessions,
    cp.remaining_sessions,
    (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as actual_booked,
    CASE
      WHEN cp.used_sessions = (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed'))
      THEN true
      ELSE false
    END as is_synced
  FROM client_packages cp
  WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
),
trigger_status AS (
  SELECT
    CASE
      WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name = 'auto_sync_package_sessions'
      ) THEN true
      ELSE false
    END as trigger_exists
),
view_status AS (
  SELECT
    CASE
      WHEN COUNT(*) > 0 THEN true
      ELSE false
    END as has_data
  FROM trainer_upcoming_sessions
  WHERE session_id IN (
    SELECT id FROM sessions
    WHERE package_id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce'
  )
)
SELECT
  '1. Active Package Found' as check_item,
  CASE WHEN ps.id IS NOT NULL THEN '✅ Yes' ELSE '❌ No' END as status
FROM package_status ps
UNION ALL
SELECT
  '2. Package Has Sessions',
  CASE WHEN ps.actual_booked > 0 THEN '✅ Yes (' || ps.actual_booked || ' sessions)' ELSE '❌ No' END
FROM package_status ps
UNION ALL
SELECT
  '3. Package Sync Status',
  CASE WHEN ps.is_synced THEN '✅ In Sync' ELSE '⚠️ Out of Sync (run PART 5)' END
FROM package_status ps
UNION ALL
SELECT
  '4. Trigger Installed',
  CASE WHEN ts.trigger_exists THEN '✅ Yes' ELSE '❌ No' END
FROM trigger_status ts
UNION ALL
SELECT
  '5. Views Return Data',
  CASE WHEN vs.has_data THEN '✅ Yes' ELSE '❌ No' END
FROM view_status vs
UNION ALL
SELECT
  '6. Ready for New Booking Test',
  CASE
    WHEN ps.is_synced AND ts.trigger_exists AND vs.has_data
    THEN '✅ Ready! Book a session and watch terminal for NOTICE'
    ELSE '⚠️ Sync package first (PART 5), then test'
  END
FROM package_status ps, trigger_status ts, view_status vs;

-- ============================================================================
-- NEXT STEPS BASED ON RESULTS:
-- ============================================================================
--
-- IF "OUT OF SYNC":
--   1. Uncomment PART 5
--   2. Run entire file again
--   3. Check PART 6 shows "IN SYNC"
--
-- IF "IN SYNC":
--   1. Note values from PART 7 (current counts)
--   2. Open Flutter app
--   3. Book ONE new session:
--      - Client: Nuttapon Kaewepsof
--      - Package: 10-Session Package (THIS package!)
--      - Date: December 5, 2025
--      - Time: 10:00 AM
--   4. Watch terminal for: "NOTICE: Session booked: Decremented package..."
--   5. Re-run this file to verify counts changed
--
-- EXPECTED AFTER NEW BOOKING:
--   - used_sessions: increased by 1
--   - remaining_sessions: decreased by 1
--   - actual_booked: increased by 1
--   - All three match perfectly (IN SYNC)
--
-- IF TRIGGER DOESN'T FIRE:
--   - Check Flutter terminal for errors
--   - Check booking succeeded ("Booking Confirmed!" dialog)
--   - Run INVESTIGATE_ALL_ERRORS.sql ERROR CHECK 6
--
-- ============================================================================
