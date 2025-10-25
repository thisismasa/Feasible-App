-- ============================================================================
-- IDENTIFY ACTIVE PACKAGE WITH SESSIONS
-- Find which package Nuttapon is actually using for bookings
-- ============================================================================

-- ============================================================================
-- PART 1: Show all Nuttapon's packages and their session counts
-- ============================================================================

SELECT
  cp.id as package_id,
  c.full_name as client_name,
  cp.package_name,
  cp.status,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.created_at,
  -- Count actual sessions linked to this package
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked_sessions,
  -- Sync status
  CASE
    WHEN (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) > 0
    THEN '⚠️ HAS SESSIONS - This is the active one!'
    WHEN cp.status = 'active' AND (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id) = 0
    THEN '✅ No sessions - Empty package'
    ELSE '❓ Check status'
  END as usage_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- PART 2: Show sessions grouped by package_id
-- ============================================================================

SELECT
  s.package_id,
  cp.package_name,
  COUNT(*) as session_count,
  MIN(s.scheduled_start) as earliest_session,
  MAX(s.scheduled_start) as latest_session,
  '⚠️ This package needs syncing' as note
FROM sessions s
LEFT JOIN client_packages cp ON s.package_id = cp.id
JOIN users c ON s.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND s.status IN ('scheduled', 'confirmed')
GROUP BY s.package_id, cp.package_name
ORDER BY session_count DESC;

-- ============================================================================
-- PART 3: Detailed view of the active package
-- ============================================================================

WITH active_package AS (
  SELECT cp.id
  FROM client_packages cp
  JOIN users c ON cp.client_id = c.id
  WHERE c.full_name ILIKE '%Nuttapon%'
    AND cp.id IN (
      SELECT DISTINCT s.package_id
      FROM sessions s
      JOIN users c2 ON s.client_id = c2.id
      WHERE c2.full_name ILIKE '%Nuttapon%'
        AND s.status IN ('scheduled', 'confirmed')
    )
  LIMIT 1
)
SELECT
  '=== ACTIVE PACKAGE DETAILS ===' as section,
  cp.id as package_id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions as current_used,
  cp.remaining_sessions as current_remaining,
  (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as actual_used,
  cp.total_sessions - (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as should_be_remaining,
  CASE
    WHEN cp.used_sessions = (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed'))
    THEN '✅ IN SYNC'
    ELSE '⚠️ OUT OF SYNC - Run sync SQL for this package'
  END as sync_status
FROM client_packages cp
WHERE cp.id = (SELECT id FROM active_package);

-- ============================================================================
-- PART 4: List all sessions for the active package
-- ============================================================================

SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.session_type,
  s.package_id,
  cp.package_name,
  '📅 Booked session' as note
FROM sessions s
LEFT JOIN client_packages cp ON s.package_id = cp.id
JOIN users c ON s.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND s.status IN ('scheduled', 'confirmed')
ORDER BY s.scheduled_start;

-- ============================================================================
-- PART 5: SYNC ONLY THE ACTIVE PACKAGE
-- ============================================================================

-- Uncomment this to sync ONLY the package that has sessions
/*
DO $$
DECLARE
  v_active_package_id UUID;
  v_actual_count INTEGER;
  v_total_sessions INTEGER;
BEGIN
  -- Find the package that has sessions
  SELECT DISTINCT s.package_id
  INTO v_active_package_id
  FROM sessions s
  JOIN users c ON s.client_id = c.id
  WHERE c.full_name ILIKE '%Nuttapon%'
    AND s.status IN ('scheduled', 'confirmed')
  LIMIT 1;

  IF v_active_package_id IS NULL THEN
    RAISE NOTICE '❌ No active package found with sessions';
    RETURN;
  END IF;

  -- Count sessions for this package
  SELECT COUNT(*)
  INTO v_actual_count
  FROM sessions s
  WHERE s.package_id = v_active_package_id
    AND s.status IN ('scheduled', 'confirmed');

  -- Get total sessions
  SELECT total_sessions
  INTO v_total_sessions
  FROM client_packages
  WHERE id = v_active_package_id;

  -- Update package counts
  UPDATE client_packages
  SET
    used_sessions = v_actual_count,
    remaining_sessions = GREATEST(v_total_sessions - v_actual_count, 0),
    updated_at = NOW()
  WHERE id = v_active_package_id;

  RAISE NOTICE '✅ Synced package: % - Used: %, Remaining: %',
    v_active_package_id,
    v_actual_count,
    GREATEST(v_total_sessions - v_actual_count, 0);
END $$;
*/

-- ============================================================================
-- INSTRUCTIONS:
-- ============================================================================
-- 1. Run PART 1-4 to see all packages and identify the active one
-- 2. Check which package has "⚠️ HAS SESSIONS - This is the active one!"
-- 3. If you want to sync that package, uncomment PART 5 and run
-- 4. Re-run PART 3 to verify sync worked
-- ============================================================================

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- PART 1: Shows all Nuttapon packages
--   - Most will show "No sessions - Empty package"
--   - ONE will show "HAS SESSIONS - This is the active one!"
--
-- PART 2: Shows which package_id has how many sessions
--   - Should show: package_id | session_count
--
-- PART 3: Shows sync status of the active package
--   - If OUT OF SYNC: used_sessions != actual_used
--
-- PART 4: Lists all booked sessions
--   - Should show session details with dates
--
-- After PART 5 (if run):
--   - used_sessions should match actual_booked
--   - remaining_sessions should equal total - actual_booked
-- ============================================================================
