-- ============================================================================
-- END-TO-END TEST: Verify complete booking workflow
-- ============================================================================

-- Step 1: Check BEFORE state - Get Nuttapon's current package state
SELECT
  cp.id as package_id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  c.full_name as client_name,
  c.id as client_id
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND cp.status = 'active'
ORDER BY cp.created_at DESC
LIMIT 1;

-- Step 2: Check how many sessions Nuttapon has booked so far
SELECT
  COUNT(*) as total_booked_sessions,
  COUNT(*) FILTER (WHERE status = 'scheduled') as scheduled_sessions,
  COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_sessions,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_sessions
FROM sessions s
JOIN users c ON s.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%';

-- Step 3: Show all Nuttapon's sessions with details
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.session_type,
  s.created_at as booked_at,
  cp.package_name,
  cp.remaining_sessions as package_remaining_after_booking
FROM sessions s
JOIN users c ON s.client_id = c.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY s.created_at DESC;

-- Step 4: Verify trigger exists and is active
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions';

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- Query 1: Should show remaining_sessions = 10 (or 9 if trigger worked on existing session)
-- Query 2: Should show 1 total_booked_sessions (from your earlier booking)
-- Query 3: Should show the session you just booked with all details
-- Query 4: Should show trigger exists with AFTER INSERT OR UPDATE
-- ============================================================================

-- ============================================================================
-- WHAT TO DO NEXT:
-- ============================================================================
-- 1. Run this SQL and note the current remaining_sessions value
-- 2. Go to Flutter app and book ONE MORE session for Nuttapon
-- 3. Come back and run Query 1 again
-- 4. Check if remaining_sessions decreased by 1
-- 5. Check terminal logs for: "Session booked: Decremented package X sessions"
-- ============================================================================
