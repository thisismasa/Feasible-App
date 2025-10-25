-- ============================================================================
-- CLEANUP: Delete ALL Duplicate 15:30 Sessions (Keep Only Oldest)
-- ============================================================================

SELECT '=== STEP 1: Show ALL 15:30 sessions ===' as step;

SELECT
  s.id,
  s.created_at,
  TO_CHAR(s.scheduled_start, 'YYYY-MM-DD HH24:MI:SS') as session_time,
  s.status,
  u.full_name as client_name,
  ROW_NUMBER() OVER (ORDER BY s.created_at) as row_num,
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
    ELSE '❌ DELETE - Duplicate'
  END as action
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
  AND EXTRACT(HOUR FROM s.scheduled_start) = 15
  AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
ORDER BY s.created_at;

-- ============================================================================
-- STEP 2: Delete ALL duplicates (keep only oldest)
-- ============================================================================

SELECT '=== STEP 2: Deleting ALL duplicates ===' as step;

WITH oldest_session AS (
  SELECT s.id as keep_id
  FROM sessions s
  JOIN users u ON u.id = s.client_id
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND s.scheduled_start::date = '2025-10-28'::date
    AND EXTRACT(HOUR FROM s.scheduled_start) = 15
    AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
  ORDER BY s.created_at ASC
  LIMIT 1
),
duplicates_to_delete AS (
  SELECT s.id
  FROM sessions s
  JOIN users u ON u.id = s.client_id
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND s.scheduled_start::date = '2025-10-28'::date
    AND EXTRACT(HOUR FROM s.scheduled_start) = 15
    AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
    AND s.id NOT IN (SELECT keep_id FROM oldest_session)
)
DELETE FROM sessions
WHERE id IN (SELECT id FROM duplicates_to_delete)
RETURNING
  id as deleted_session_id,
  scheduled_start,
  '✅ Duplicate deleted' as result;

-- ============================================================================
-- STEP 3: Count how many were deleted and update package
-- ============================================================================

SELECT '=== STEP 3: Update package counts ===' as step;

WITH delete_count AS (
  -- This will be 0 after deletion, but we need to know how many we deleted
  -- Let's calculate based on current package vs expected
  SELECT
    cp.id as package_id,
    cp.used_sessions,
    cp.remaining_sessions,
    COUNT(s.id) as actual_sessions_now,
    cp.used_sessions - COUNT(s.id) as sessions_to_refund
  FROM client_packages cp
  JOIN users u ON u.id = cp.client_id
  LEFT JOIN sessions s ON s.package_id = cp.id AND s.status IN ('scheduled', 'confirmed')
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND cp.status = 'active'
  GROUP BY cp.id, cp.used_sessions, cp.remaining_sessions
  LIMIT 1
)
UPDATE client_packages cp
SET
  used_sessions = dc.actual_sessions_now,
  remaining_sessions = cp.total_sessions - dc.actual_sessions_now,
  updated_at = NOW()
FROM delete_count dc
WHERE cp.id = dc.package_id
RETURNING
  cp.id,
  cp.used_sessions as sessions_used_after_cleanup,
  cp.remaining_sessions as sessions_remaining_after_cleanup,
  '✅ Package synced to actual session count' as result;

-- ============================================================================
-- STEP 4: Verify only ONE 15:30 session remains
-- ============================================================================

SELECT '=== STEP 4: Final verification ===' as step;

SELECT
  COUNT(*) as remaining_1530_sessions,
  CASE
    WHEN COUNT(*) = 1 THEN '✅ SUCCESS - Only one 15:30 session remains!'
    WHEN COUNT(*) > 1 THEN '❌ PROBLEM - Still have ' || COUNT(*) || ' duplicates!'
    ELSE '⚠️ WARNING - No sessions found (deleted too many?)'
  END as status
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
  AND EXTRACT(HOUR FROM s.scheduled_start) = 15
  AND EXTRACT(MINUTE FROM s.scheduled_start) = 30;

-- ============================================================================
-- STEP 5: Show final session list for Oct 28
-- ============================================================================

SELECT '=== STEP 5: All remaining sessions on Oct 28 ===' as step;

SELECT
  TO_CHAR(s.scheduled_start, 'HH24:MI') as time,
  s.duration_minutes as duration,
  s.status,
  u.full_name as client,
  s.created_at,
  '✅ Cleaned up' as status_note
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
ORDER BY s.scheduled_start;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- STEP 1: Shows all 5 duplicate 15:30 sessions
-- STEP 2: Deletes 4 duplicates (keeps oldest)
-- STEP 3: Updates package: used_sessions should decrease by 4
-- STEP 4: Shows "✅ SUCCESS - Only one 15:30 session remains!"
-- STEP 5: Shows clean schedule with no duplicates
-- ============================================================================
