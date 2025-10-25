-- ============================================================================
-- CLEANUP: Delete ONE Duplicate 15:30 Session
-- ============================================================================
-- This will delete the NEWER of the two duplicate sessions, keeping the older one

SELECT '=== STEP 1: Show all 15:30 sessions on Oct 28 ===' as step;

SELECT
  s.id,
  s.created_at,
  TO_CHAR(s.scheduled_start, 'YYYY-MM-DD HH24:MI') as session_time,
  s.status,
  u.full_name as client_name,
  CASE
    WHEN s.created_at = (
      SELECT MIN(s2.created_at)
      FROM sessions s2
      JOIN users u2 ON u2.id = s2.client_id
      WHERE u2.full_name ILIKE '%Nuttapon%'
        AND s2.scheduled_start::date = '2025-10-28'::date
        AND EXTRACT(HOUR FROM s2.scheduled_start) = 15
        AND EXTRACT(MINUTE FROM s2.scheduled_start) = 30
    )
    THEN '✅ KEEP - Oldest session'
    ELSE '❌ DELETE - Duplicate (newer)'
  END as action
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
  AND EXTRACT(HOUR FROM s.scheduled_start) = 15
  AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
ORDER BY s.created_at;

-- ============================================================================
-- STEP 2: Delete the NEWER duplicate session
-- ============================================================================

SELECT '=== STEP 2: Deleting duplicate session ===' as step;

WITH duplicate_to_delete AS (
  SELECT s.id
  FROM sessions s
  JOIN users u ON u.id = s.client_id
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND s.scheduled_start::date = '2025-10-28'::date
    AND EXTRACT(HOUR FROM s.scheduled_start) = 15
    AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
  ORDER BY s.created_at DESC
  LIMIT 1
)
DELETE FROM sessions
WHERE id IN (SELECT id FROM duplicate_to_delete)
RETURNING
  id as deleted_session_id,
  scheduled_start,
  '✅ Duplicate deleted' as result;

-- ============================================================================
-- STEP 3: Update package counts (refund the deleted session)
-- ============================================================================

SELECT '=== STEP 3: Updating package counts ===' as step;

WITH nuttapon_package AS (
  SELECT cp.id, cp.used_sessions, cp.remaining_sessions
  FROM client_packages cp
  JOIN users u ON u.id = cp.client_id
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND cp.status = 'active'
  ORDER BY cp.created_at DESC
  LIMIT 1
)
UPDATE client_packages
SET
  used_sessions = used_sessions - 1,
  remaining_sessions = remaining_sessions + 1,
  updated_at = NOW()
WHERE id IN (SELECT id FROM nuttapon_package)
RETURNING
  id,
  used_sessions as sessions_used_after_delete,
  remaining_sessions as sessions_remaining_after_delete,
  '✅ Package counts updated' as result;

-- ============================================================================
-- STEP 4: Verify only ONE 15:30 session remains
-- ============================================================================

SELECT '=== STEP 4: Verify cleanup ===' as step;

SELECT
  COUNT(*) as remaining_1530_sessions,
  CASE
    WHEN COUNT(*) = 1 THEN '✅ GOOD - Only one 15:30 session remains'
    WHEN COUNT(*) > 1 THEN '❌ PROBLEM - Still have duplicates!'
    ELSE '⚠️ WARNING - No sessions found'
  END as status
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
  AND EXTRACT(HOUR FROM s.scheduled_start) = 15
  AND EXTRACT(MINUTE FROM s.scheduled_start) = 30;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- STEP 1: Shows both sessions, marks newer one for deletion
-- STEP 2: Deletes the newer duplicate
-- STEP 3: Refunds 1 session back to package (used-1, remaining+1)
-- STEP 4: Shows only 1 session remaining
-- ============================================================================
