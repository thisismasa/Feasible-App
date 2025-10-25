-- ============================================================================
-- CHECK: What statuses does trainer_upcoming_sessions view show?
-- ============================================================================

SELECT '=== Check trainer_upcoming_sessions view definition ===' as step;

SELECT
  schemaname,
  viewname,
  definition
FROM pg_views
WHERE viewname = 'trainer_upcoming_sessions'
  AND schemaname = 'public';

-- Show what statuses are currently being filtered
SELECT '=== Current sessions in view ===' as step;

SELECT
  session_id,
  client_name,
  scheduled_start,
  status,
  CASE
    WHEN status = 'cancelled' THEN '❌ CANCELLED - Should NOT show in UI!'
    WHEN status IN ('scheduled', 'confirmed') THEN '✅ Should show'
    ELSE '⚠️ Other status'
  END as should_show
FROM trainer_upcoming_sessions
ORDER BY scheduled_start;
