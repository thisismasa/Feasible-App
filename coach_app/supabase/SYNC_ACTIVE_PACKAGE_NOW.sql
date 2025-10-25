-- ============================================================================
-- SYNC ACTIVE PACKAGE - Ready to Run
-- ============================================================================
-- This will sync package: 2c495497-2ba3-4a87-8e36-3bf0a8bcfbce
-- Current state: 9 sessions booked, but counters OUT OF SYNC
-- ============================================================================

-- ============================================================================
-- BEFORE SYNC: Current State
-- ============================================================================

SELECT '=== BEFORE SYNC ===' as section;

SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions as current_used,
  cp.remaining_sessions as current_remaining,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked,
  '⚠️ OUT OF SYNC' as status
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- PERFORM SYNC
-- ============================================================================

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
  RAISE NOTICE '   Total sessions: %', v_total_sessions;
  RAISE NOTICE '   Used sessions: %', v_actual_count;
  RAISE NOTICE '   Remaining sessions: %', GREATEST(v_total_sessions - v_actual_count, 0);
END $$;

-- ============================================================================
-- AFTER SYNC: Verify Result
-- ============================================================================

SELECT '=== AFTER SYNC ===' as section;

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
    ELSE '❌ STILL OUT OF SYNC'
  END as status
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- PREPARE FOR TRIGGER TEST
-- ============================================================================

SELECT '=== READY FOR TRIGGER TEST ===' as section;

SELECT
  'CURRENT STATE (write these down):' as instruction,
  cp.used_sessions as current_used,
  cp.remaining_sessions as current_remaining,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as current_actual,
  '📝 Record these values!' as note
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

SELECT
  'AFTER BOOKING NEW SESSION, EXPECT:' as instruction,
  cp.used_sessions + 1 as expected_used,
  cp.remaining_sessions - 1 as expected_remaining,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) + 1 as expected_actual,
  '⚠️ Watch terminal for NOTICE!' as important
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- BEFORE SYNC:
--   used_sessions: 0 (or wrong value)
--   remaining_sessions: 10 (or wrong value)
--   actual_booked: 9
--   status: OUT OF SYNC
--
-- AFTER SYNC:
--   used_sessions: 9 ✅
--   remaining_sessions: 1 ✅
--   actual_booked: 9
--   status: IN SYNC ✅
--
-- NEXT STEP:
--   Book ONE new session in Flutter
--   Watch for: "NOTICE: Session booked: Decremented package..."
--   Re-run to verify: used=10, remaining=0, actual=10
-- ============================================================================
