-- ============================================================================
-- OPTIONAL: Manually sync old sessions to package counts
-- ============================================================================
-- Purpose: Update package counts to reflect sessions booked BEFORE trigger install
-- WARNING: Only run this if you want to retroactively count old bookings!
-- ============================================================================

-- ============================================================================
-- PART 1: Preview what will be updated (DRY RUN)
-- ============================================================================

SELECT
  cp.id as package_id,
  c.full_name as client_name,
  cp.package_name,
  -- Current state
  cp.total_sessions as current_total,
  cp.used_sessions as current_used,
  cp.remaining_sessions as current_remaining,
  -- Actual booked sessions
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as actual_booked,
  -- What it SHOULD be
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as should_be_used,
  cp.total_sessions - (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status IN ('scheduled', 'confirmed')
  ) as should_be_remaining,
  -- Sync status
  CASE
    WHEN cp.used_sessions = (
      SELECT COUNT(*)
      FROM sessions s
      WHERE s.package_id = cp.id
        AND s.status IN ('scheduled', 'confirmed')
    ) THEN '✅ Already in sync'
    ELSE '⚠️ Needs sync'
  END as sync_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE cp.status = 'active'
ORDER BY sync_status DESC, c.full_name;

-- ============================================================================
-- PART 2: Perform the sync (WRITES DATA!)
-- ============================================================================
-- Uncomment this section only if you want to sync old sessions!
-- This will update ALL active packages to match their actual session counts
-- ============================================================================

/*
DO $$
DECLARE
  v_package RECORD;
  v_actual_count INTEGER;
  v_packages_updated INTEGER := 0;
BEGIN
  -- Loop through all active packages
  FOR v_package IN
    SELECT
      cp.id,
      cp.package_name,
      cp.total_sessions,
      c.full_name as client_name
    FROM client_packages cp
    JOIN users c ON cp.client_id = c.id
    WHERE cp.status = 'active'
  LOOP
    -- Count actual booked sessions for this package
    SELECT COUNT(*)
    INTO v_actual_count
    FROM sessions s
    WHERE s.package_id = v_package.id
      AND s.status IN ('scheduled', 'confirmed');

    -- Update package counts
    UPDATE client_packages
    SET
      used_sessions = v_actual_count,
      remaining_sessions = GREATEST(v_package.total_sessions - v_actual_count, 0),
      updated_at = NOW()
    WHERE id = v_package.id;

    v_packages_updated := v_packages_updated + 1;

    RAISE NOTICE 'Synced package: % (%) - Used: %, Remaining: %',
      v_package.client_name,
      v_package.package_name,
      v_actual_count,
      GREATEST(v_package.total_sessions - v_actual_count, 0);
  END LOOP;

  RAISE NOTICE '✅ Synced % packages total', v_packages_updated;
END $$;
*/

-- ============================================================================
-- PART 3: Verify sync worked
-- ============================================================================

SELECT
  c.full_name as client_name,
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
    ) THEN '✅ IN SYNC'
    ELSE '❌ STILL OUT OF SYNC'
  END as sync_status
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE cp.status = 'active'
ORDER BY c.full_name;

-- ============================================================================
-- USAGE INSTRUCTIONS:
-- ============================================================================
-- 1. First run PART 1 (preview) to see what will be updated
-- 2. Review the "should_be_used" and "should_be_remaining" columns
-- 3. If numbers look correct, uncomment PART 2 and run entire file
-- 4. Check PART 3 results - all should show "✅ IN SYNC"
-- ============================================================================

-- ============================================================================
-- WHEN TO USE THIS:
-- ============================================================================
-- Use this script if:
-- ✅ You have old sessions (booked before trigger was installed)
-- ✅ Package counts show OUT OF SYNC
-- ✅ You want historical sessions to be counted
--
-- DON'T use this if:
-- ❌ You only care about future bookings (trigger handles those)
-- ❌ Counts are already correct
-- ❌ You're not sure what this does
-- ============================================================================

-- ============================================================================
-- EXAMPLE OUTPUT (PART 1 - Preview):
-- ============================================================================
-- client_name     | package_name        | current_used | actual_booked | sync_status
-- ================|=====================|==============|===============|=================
-- Nuttapon K.     | 10-Session Package  | 0            | 8             | ⚠️ Needs sync
--
-- After running PART 2:
-- client_name     | package_name        | used_sessions | remaining | sync_status
-- ================|=====================|===============|===========|=============
-- Nuttapon K.     | 10-Session Package  | 8             | 2         | ✅ IN SYNC
-- ============================================================================
