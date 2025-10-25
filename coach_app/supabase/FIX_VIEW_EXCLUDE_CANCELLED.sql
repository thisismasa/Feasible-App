-- ============================================================================
-- FIX: Update trainer_upcoming_sessions view to exclude cancelled sessions
-- ============================================================================

SELECT '=== STEP 1: Drop old view ===' as step;

DROP VIEW IF EXISTS trainer_upcoming_sessions CASCADE;

SELECT 'Old view dropped' as result;

-- ============================================================================
-- STEP 2: Create new view that EXCLUDES cancelled sessions
-- ============================================================================

SELECT '=== STEP 2: Creating new view with status filter ===' as step;

CREATE VIEW trainer_upcoming_sessions AS
SELECT
  s.id as session_id,
  s.trainer_id,
  s.client_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.package_id,
  s.notes,
  s.location,
  -- Client details
  COALESCE(c.first_name || ' ' || c.last_name, c.email) as client_name,
  c.email as client_email,
  c.phone as client_phone,
  -- Package details
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions
FROM sessions s
LEFT JOIN clients c ON s.client_id = c.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.scheduled_start >= NOW()  -- Only future sessions
  AND s.status IN ('scheduled', 'confirmed')  -- ✅ EXCLUDE cancelled, completed, no_show
ORDER BY s.scheduled_start;

SELECT '✅ View created with status filter' as result;

-- ============================================================================
-- STEP 3: Grant permissions
-- ============================================================================

SELECT '=== STEP 3: Granting permissions ===' as step;

GRANT SELECT ON trainer_upcoming_sessions TO authenticated;
GRANT SELECT ON trainer_upcoming_sessions TO anon;

SELECT '✅ Permissions granted' as result;

-- ============================================================================
-- STEP 4: Verify - show what's in the view now
-- ============================================================================

SELECT '=== STEP 4: Verify view contents ===' as step;

SELECT
  session_id,
  client_name,
  scheduled_start,
  status,
  '✅ This session SHOULD show in UI' as note
FROM trainer_upcoming_sessions
ORDER BY scheduled_start
LIMIT 10;

-- Check if any cancelled sessions are still visible
SELECT
  CASE
    WHEN COUNT(*) = 0 THEN '✅ No cancelled sessions in view - CORRECT!'
    ELSE '❌ Still showing ' || COUNT(*) || ' cancelled sessions!'
  END as verification
FROM trainer_upcoming_sessions
WHERE status = 'cancelled';

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- 1. View recreated
-- 2. Only shows status IN ('scheduled', 'confirmed')
-- 3. Cancelled sessions are excluded
-- 4. UI will no longer show cancelled sessions
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'View now excludes cancelled sessions' as note;
SELECT 'Refresh the Flutter app to see the change!' as next_step;
