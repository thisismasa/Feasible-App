-- ============================================================================
-- TEMPORARY: Add more sessions to package for testing
-- ============================================================================
-- This adds 5 more sessions to the package so we can test the trigger
-- ============================================================================

-- First, check current state
SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as actual_booked
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- Add 5 more sessions to the package (temporary for testing)
UPDATE client_packages
SET
  total_sessions = total_sessions + 5,
  remaining_sessions = remaining_sessions + 5,
  updated_at = NOW()
WHERE id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- Verify the update
SELECT
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')) as actual_booked,
  '✅ Now has ' || cp.remaining_sessions || ' remaining sessions' as status
FROM client_packages cp
WHERE cp.id = '2c495497-2ba3-4a87-8e36-3bf0a8bcfbce';

-- ============================================================================
-- RESULT:
-- ============================================================================
-- If package had: total=10, used=9, remaining=1
-- Now has: total=15, used=9, remaining=6
--
-- This gives us 6 sessions to test with!
-- ============================================================================

-- ============================================================================
-- NEXT STEPS:
-- ============================================================================
-- 1. Try booking again in Flutter
-- 2. Should work now (remaining > 0)
-- 3. Watch terminal for trigger NOTICE
-- 4. Verify counts decrease: remaining goes from 6 → 5
-- ============================================================================
