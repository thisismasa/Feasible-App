-- ============================================================================
-- FIX: Create simple view without non-existent columns
-- ============================================================================

SELECT '=== STEP 1: Check users table columns ===' as step;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- STEP 2: Drop old view
-- ============================================================================

SELECT '=== STEP 2: Drop old view ===' as step;

DROP VIEW IF EXISTS trainer_upcoming_sessions CASCADE;

-- ============================================================================
-- STEP 3: Create simple view (only use columns that exist)
-- ============================================================================

SELECT '=== STEP 3: Creating simple view ===' as step;

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
  -- User details (use only email - safest)
  u.email as client_name,
  u.email as client_email,
  u.phone as client_phone,
  -- Package details
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions
FROM sessions s
LEFT JOIN users u ON s.client_id = u.id
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.scheduled_start >= NOW()
  AND s.status IN ('scheduled', 'confirmed')  -- ✅ EXCLUDE cancelled sessions
ORDER BY s.scheduled_start;

GRANT SELECT ON trainer_upcoming_sessions TO authenticated;
GRANT SELECT ON trainer_upcoming_sessions TO anon;

SELECT '✅ View created' as result;

-- ============================================================================
-- STEP 4: Verify no cancelled sessions
-- ============================================================================

SELECT '=== STEP 4: Verification ===' as step;

SELECT
  COUNT(*) as total_in_view,
  COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
  CASE
    WHEN COUNT(*) FILTER (WHERE status = 'cancelled') = 0
    THEN '✅ No cancelled sessions in view!'
    ELSE '❌ Still has cancelled sessions'
  END as verification
FROM trainer_upcoming_sessions;

-- Show what's in the view
SELECT
  session_id,
  client_name,
  scheduled_start,
  status
FROM trainer_upcoming_sessions
ORDER BY scheduled_start
LIMIT 5;

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'Refresh Flutter to see cancelled session disappear!' as next_step;
