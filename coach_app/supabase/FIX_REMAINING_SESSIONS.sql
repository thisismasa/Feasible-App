-- ============================================================================
-- FIX REMAINING SESSIONS - Update broken packages
-- ============================================================================
-- Problem: remaining_sessions column defaults to 0 and is NOT auto-calculated
-- When packages are created, they have remaining_sessions = 0 even though
-- they should have remaining_sessions = total_sessions - used_sessions
-- ============================================================================

-- Check current state
SELECT '========== BEFORE FIX ==========' as status;
SELECT
  id,
  client_id,
  package_name,
  total_sessions,
  used_sessions,
  remaining_sessions,
  status,
  created_at
FROM client_packages
WHERE remaining_sessions = 0
  AND total_sessions > 0
  AND status = 'active'
ORDER BY created_at DESC;

-- Fix all broken packages
UPDATE client_packages
SET remaining_sessions = total_sessions - used_sessions
WHERE remaining_sessions != (total_sessions - used_sessions)
   OR remaining_sessions IS NULL;

-- Check after fix
SELECT '========== AFTER FIX ==========' as status;
SELECT
  id,
  client_id,
  package_name,
  total_sessions,
  used_sessions,
  remaining_sessions,
  status,
  created_at
FROM client_packages
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 10;

-- Create a trigger to auto-calculate remaining_sessions on INSERT/UPDATE
CREATE OR REPLACE FUNCTION update_remaining_sessions()
RETURNS TRIGGER AS $$
BEGIN
  NEW.remaining_sessions := NEW.total_sessions - NEW.used_sessions;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_remaining_sessions ON client_packages;

CREATE TRIGGER trigger_update_remaining_sessions
  BEFORE INSERT OR UPDATE ON client_packages
  FOR EACH ROW
  EXECUTE FUNCTION update_remaining_sessions();

-- Verify trigger works
SELECT '========== TRIGGER CREATED ==========' as status;
SELECT 'Trigger will auto-calculate remaining_sessions on INSERT/UPDATE' as info;

-- Test with a sample update
SELECT '========== TESTING TRIGGER ==========' as status;
UPDATE client_packages
SET used_sessions = used_sessions
WHERE id IN (
  SELECT id FROM client_packages LIMIT 1
);

-- Show final state
SELECT '========== FINAL VERIFICATION ==========' as status;
SELECT
  u.full_name as client_name,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  cp.status
FROM client_packages cp
JOIN users u ON u.id = cp.client_id
WHERE cp.status = 'active'
ORDER BY cp.created_at DESC
LIMIT 10;

SELECT '✅ Fixed remaining_sessions for all packages!' as status;
SELECT 'Trigger created to auto-calculate going forward' as trigger_status;
