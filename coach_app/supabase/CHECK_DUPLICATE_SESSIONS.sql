-- ============================================================================
-- CHECK: When Were the Duplicate 15:30 Sessions Created?
-- ============================================================================
-- This will show if the duplicates existed BEFORE our fix, or were created AFTER

SELECT
  '=== DUPLICATE 15:30 SESSIONS ===' as section;

-- Get all 15:30 sessions for Nuttapon on Oct 28
SELECT
  s.id,
  s.created_at,
  s.scheduled_start,
  TO_CHAR(s.scheduled_start, 'YYYY-MM-DD HH24:MI') as session_time,
  s.status,
  u.full_name as client_name,
  s.package_id,
  '🔍 When was this created?' as question
FROM sessions s
JOIN users u ON u.id = s.client_id
WHERE u.full_name ILIKE '%Nuttapon%'
  AND s.scheduled_start::date = '2025-10-28'::date
  AND EXTRACT(HOUR FROM s.scheduled_start) = 15
  AND EXTRACT(MINUTE FROM s.scheduled_start) = 30
ORDER BY s.created_at;

-- ============================================================================
-- NEXT: Test if database function prevents NEW duplicates
-- ============================================================================

SELECT '=== TEST: Try to book ANOTHER 15:30 session ===' as test_section;

-- Get client and trainer IDs
WITH test_data AS (
  SELECT
    u.id as client_id,
    s.trainer_id,
    s.package_id
  FROM sessions s
  JOIN users u ON u.id = s.client_id
  WHERE u.full_name ILIKE '%Nuttapon%'
    AND s.scheduled_start::date = '2025-10-28'::date
  LIMIT 1
)
SELECT
  'Attempting to book duplicate 15:30...' as test_description,
  book_session_with_validation(
    (SELECT client_id FROM test_data),
    (SELECT trainer_id FROM test_data),
    '2025-10-28 15:30:00+00'::timestamptz,
    60,
    (SELECT package_id FROM test_data),
    'in_person',
    'Test Location',
    'Testing if conflict detection works'
  ) as result;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- If fix is working:
--   { "success": false, "error": "You already have a session booked at this time" }
--
-- If fix NOT working:
--   { "success": true, "session_id": "..." } ← BAD! Should have blocked it!
-- ============================================================================
