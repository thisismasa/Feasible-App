-- ============================================================================
-- DEBUG: Check EXACT current state
-- ============================================================================

-- Step 1: Show the EXACT client IDs Flutter is checking
SELECT
  'Step 1: Client IDs' as step,
  id,
  full_name,
  email
FROM users
WHERE email IN ('nattapon@gmail.com', 'nutgaporn@gmail.com')
   OR id IN ('db18b246-63dc-4627-91b3-6bb6bb8a5a95', '592e5eb0-5886-409e-ab2e-1f0969dd0d51');

-- Step 2: Show ALL packages for these clients
SELECT
  'Step 2: ALL packages' as step,
  cp.id,
  cp.client_id,
  cp.package_name,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.status,
  cp.payment_status,
  cp.created_at
FROM client_packages cp
WHERE cp.client_id IN (
  'db18b246-63dc-4627-91b3-6bb6bb8a5a95',
  '592e5eb0-5886-409e-ab2e-1f0969dd0d51'
)
ORDER BY cp.created_at DESC;

-- Step 3: Check if sessions_remaining is NULL or 0
SELECT
  'Step 3: Sessions remaining details' as step,
  cp.id,
  u.full_name,
  cp.total_sessions,
  cp.sessions_remaining,
  CASE
    WHEN cp.sessions_remaining IS NULL THEN '❌ NULL'
    WHEN cp.sessions_remaining = 0 THEN '❌ ZERO'
    WHEN cp.sessions_remaining > 0 THEN '✅ Has sessions: ' || cp.sessions_remaining::text
    ELSE '⚠️ Negative'
  END as status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.client_id IN (
  'db18b246-63dc-4627-91b3-6bb6bb8a5a95',
  '592e5eb0-5886-409e-ab2e-1f0969dd0d51'
)
ORDER BY cp.created_at DESC;

-- Step 4: Manually calculate what sessions_remaining SHOULD be
SELECT
  'Step 4: Manual calculation' as step,
  cp.id,
  u.full_name,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  (cp.total_sessions - COALESCE(cp.sessions_used, 0) - COALESCE(cp.sessions_scheduled, 0)) as calculated_remaining,
  cp.sessions_remaining as actual_remaining,
  CASE
    WHEN cp.sessions_remaining = (cp.total_sessions - COALESCE(cp.sessions_used, 0) - COALESCE(cp.sessions_scheduled, 0))
    THEN '✅ Match'
    ELSE '❌ Mismatch'
  END as matches
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.client_id IN (
  'db18b246-63dc-4627-91b3-6bb6bb8a5a95',
  '592e5eb0-5886-409e-ab2e-1f0969dd0d51'
)
ORDER BY cp.created_at DESC;

-- Step 5: Check if column is GENERATED
SELECT
  'Step 5: Column definition' as step,
  column_name,
  data_type,
  is_nullable,
  is_generated,
  generation_expression
FROM information_schema.columns
WHERE table_name = 'client_packages'
  AND column_name = 'sessions_remaining';
