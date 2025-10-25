-- ============================================================================
-- QUICK CHECK: Package count status for Nuttapon
-- ============================================================================

SELECT
  'PACKAGE STATUS' as check_type,
  cp.id as package_id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  (
    SELECT COUNT(*)
    FROM sessions s
    WHERE s.package_id = cp.id
      AND s.status = 'scheduled'
  ) as actual_booked_sessions,
  CASE
    WHEN cp.used_sessions = (SELECT COUNT(*) FROM sessions s WHERE s.package_id = cp.id AND s.status = 'scheduled')
    THEN '✅ SYNCED'
    ELSE '⚠️ OUT OF SYNC (trigger will sync NEW bookings)'
  END as sync_status,
  CASE
    WHEN cp.used_sessions + cp.remaining_sessions = cp.total_sessions
    THEN '✅ MATH CORRECT'
    ELSE '❌ MATH WRONG'
  END as math_check
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC
LIMIT 1;

-- ============================================================================
-- INTERPRETATION:
-- ============================================================================
-- If OUT OF SYNC:
--   - Old sessions (booked before trigger) don't affect counts
--   - This is NORMAL and EXPECTED
--   - NEW bookings WILL sync correctly
--
-- If SYNCED:
--   - All sessions accounted for
--   - Counts are accurate
--   - Everything working perfectly
--
-- If MATH WRONG:
--   - Data corruption - need to fix
--   - Should never happen with trigger
-- ============================================================================
