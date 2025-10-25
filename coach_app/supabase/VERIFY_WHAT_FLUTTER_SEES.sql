-- ============================================================================
-- VERIFY WHAT FLUTTER APP SEES
-- ============================================================================
-- This mimics the EXACT query that Flutter makes to check for active packages
-- ============================================================================

-- This is what Flutter queries (from real_supabase_service.dart:712-725)
SELECT
  '🔍 WHAT FLUTTER SEES (exact query)' as query_name,
  cp.*,
  p.name as package_name_from_packages_table,
  p.sessions as sessions_from_packages_table
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE email = 'nattapon@gmail.com'
    OR phone = '0987654321'
)
  AND cp.status = 'active'
ORDER BY cp.created_at DESC;

-- Check if remaining_sessions is calculated correctly
SELECT
  '📊 SESSIONS REMAINING CALCULATION' as check_name,
  cp.id,
  cp.package_name,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.status,
  cp.payment_status,
  CASE
    WHEN cp.sessions_remaining > 0 THEN '✅ Has sessions'
    WHEN cp.sessions_remaining = 0 THEN '❌ ZERO sessions'
    WHEN cp.sessions_remaining IS NULL THEN '❌ NULL sessions'
    ELSE '⚠️ Negative sessions'
  END as issue
FROM client_packages cp
WHERE cp.client_id IN (
  SELECT id FROM users
  WHERE email = 'nattapon@gmail.com'
)
ORDER BY cp.created_at DESC;

-- Show the exact data Flutter needs
SELECT
  '✅ FINAL CHECK - What should show in app' as final_check,
  u.full_name,
  u.email,
  cp.status,
  cp.payment_status,
  cp.sessions_remaining,
  CASE
    WHEN cp.status = 'active'
      AND cp.payment_status = 'paid'
      AND cp.sessions_remaining > 0
    THEN '✅ SHOULD SHOW AS ACTIVE'
    ELSE '❌ WILL SHOW NO ACTIVE PACKAGE'
  END as what_app_shows
FROM users u
JOIN client_packages cp ON u.id = cp.client_id
WHERE u.email = 'nattapon@gmail.com'
ORDER BY cp.created_at DESC
LIMIT 1;
