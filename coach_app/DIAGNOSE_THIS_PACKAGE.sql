-- ============================================================================
-- DIAGNOSE SPECIFIC PACKAGE - Nadtaporn Koeiftj
-- ============================================================================
-- Package ID from your error: c594dca7-4ed8-435a-9a6e-795327f23597
-- Client ID: 592e5eb0-5886-409e-ab2e-1f0969dd0d51
-- ============================================================================

-- Check if 'status' column exists
SELECT
  '🔍 SCHEMA CHECK' as section,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages'
      AND column_name = 'status'
  ) as "status_column_exists";

-- Show what columns DO exist
SELECT
  '📋 EXISTING COLUMNS' as section,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'client_packages'
ORDER BY ordinal_position;

-- Check this specific package
SELECT
  '📦 PACKAGE DATA' as section,
  id as package_id,
  client_id,
  package_id as plan_id,
  package_name,
  is_active as "has_is_active_column",
  remaining_sessions,
  total_sessions,
  used_sessions,
  expiry_date,
  start_date,
  purchase_date,
  created_at
FROM client_packages
WHERE id = 'c594dca7-4ed8-435a-9a6e-795327f23597';

-- Check if the package plan exists and is active
SELECT
  '🎯 PACKAGE PLAN STATUS' as section,
  p.id as plan_id,
  p.name as plan_name,
  p.sessions,
  p.price,
  p.is_active as plan_is_active
FROM packages p
WHERE p.id = (
  SELECT package_id FROM client_packages WHERE id = 'c594dca7-4ed8-435a-9a6e-795327f23597'
);

-- Show what the database function is trying to query
SELECT
  '🔍 WHAT FUNCTION QUERIES' as section,
  id,
  client_id,
  package_id,
  package_name,
  -- Try to select 'status' column (will fail if it doesn't exist)
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'client_packages' AND column_name = 'status'
    )
    THEN 'status column exists, but need to check its value'
    ELSE '❌ status column DOES NOT EXIST - this is the problem!'
  END as diagnosis
FROM client_packages
WHERE id = 'c594dca7-4ed8-435a-9a6e-795327f23597';

-- Try the exact query that book_session_with_validation uses
SELECT
  '⚠️ SIMULATING DATABASE FUNCTION QUERY' as section,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'client_packages' AND column_name = 'status'
    )
    THEN (
      SELECT id FROM client_packages
      WHERE id = 'c594dca7-4ed8-435a-9a6e-795327f23597'
        AND client_id = '592e5eb0-5886-409e-ab2e-1f0969dd0d51'
        -- AND status = 'active'  -- This would fail if status doesn't exist
      LIMIT 1
    )::TEXT
    ELSE '❌ Cannot query status column - it does not exist'
  END as result,
  CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'client_packages' AND column_name = 'status'
    )
    THEN '🚨 THIS IS WHY YOU GET "Package not found or inactive"'
    ELSE 'Status column exists, checking further...'
  END as explanation;

-- Show the fix needed
SELECT
  '✅ THE FIX' as section,
  'Run QUICK_FIX_NOW.sql to add the missing status column' as what_to_do,
  'The database function queries: WHERE status = ''active''' as why_it_fails,
  'But the status column does not exist in client_packages table!' as root_cause,
  'Once you add the status column, booking will work' as solution;

-- ============================================================================
-- EXPECTED DIAGNOSIS:
-- ============================================================================
-- status_column_exists: FALSE
-- diagnosis: ❌ status column DOES NOT EXIST - this is the problem!
-- result: ❌ Cannot query status column - it does not exist
-- explanation: 🚨 THIS IS WHY YOU GET "Package not found or inactive"
-- ============================================================================
