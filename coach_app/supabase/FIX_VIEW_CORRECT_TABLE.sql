-- ============================================================================
-- FIX: Create view with correct table name (users, not clients)
-- ============================================================================

SELECT '=== STEP 1: Drop old view ===' as step;

DROP VIEW IF EXISTS trainer_upcoming_sessions CASCADE;

SELECT '✅ Old view dropped' as result;

-- ============================================================================
-- STEP 2: Check what tables exist
-- ============================================================================

SELECT '=== STEP 2: Available tables ===' as step;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name IN ('users', 'clients', 'sessions', 'client_packages')
ORDER BY table_name;

-- ============================================================================
-- STEP 3: Create view with USERS table (not clients)
-- ============================================================================

SELECT '=== STEP 3: Creating view with correct table ===' as step;

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
  -- User/Client details (from users table)
  COALESCE(u.first_name || ' ' || u.last_name, u.email) as client_name,
  u.email as client_email,
  u.phone as client_phone,
  -- Package details
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions
FROM sessions s
LEFT JOIN users u ON s.client_id = u.id  -- ✅ Use 'users' table
LEFT JOIN client_packages cp ON s.package_id = cp.id
WHERE s.scheduled_start >= NOW()  -- Only future sessions
  AND s.status IN ('scheduled', 'confirmed')  -- ✅ EXCLUDE cancelled
ORDER BY s.scheduled_start;

GRANT SELECT ON trainer_upcoming_sessions TO authenticated;
GRANT SELECT ON trainer_upcoming_sessions TO anon;

SELECT '✅ View created successfully' as result;

-- ============================================================================
-- STEP 4: Verify - cancelled sessions should NOT appear
-- ============================================================================

SELECT '=== STEP 4: Verify view contents ===' as step;

SELECT
  COUNT(*) as total_sessions,
  COUNT(*) FILTER (WHERE status = 'scheduled') as scheduled_count,
  COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_count,
  COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
  CASE
    WHEN COUNT(*) FILTER (WHERE status = 'cancelled') = 0
    THEN '✅ No cancelled sessions - CORRECT!'
    ELSE '❌ Still showing cancelled sessions!'
  END as verification
FROM trainer_upcoming_sessions;

-- Show current sessions in view
SELECT
  session_id,
  client_name,
  scheduled_start,
  status,
  '✅ Should appear in UI' as note
FROM trainer_upcoming_sessions
ORDER BY scheduled_start
LIMIT 5;

-- ============================================================================
-- EXPECTED RESULT:
-- ============================================================================
-- 1. View recreated with users table
-- 2. Only shows status IN ('scheduled', 'confirmed')
-- 3. cancelled_count = 0
-- 4. UI will refresh and hide cancelled sessions
-- ============================================================================

SELECT '=== ✅ COMPLETE ===' as final_message;
SELECT 'View fixed. Refresh Flutter to see cancelled session disappear!' as next_step;
