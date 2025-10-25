-- ============================================================================
-- FINAL COMPLETE FIX - Fix Everything and Show Results
-- ============================================================================

-- STEP 1: Ensure sessions_remaining column exists as GENERATED
-- ============================================================================
DO $$
BEGIN
  -- Drop the column if it exists and is not generated
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages'
      AND column_name = 'sessions_remaining'
      AND is_generated = 'NEVER'
  ) THEN
    ALTER TABLE client_packages DROP COLUMN sessions_remaining;
    RAISE NOTICE 'Dropped old sessions_remaining column';
  END IF;

  -- Create as GENERATED ALWAYS column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'client_packages'
      AND column_name = 'sessions_remaining'
  ) THEN
    ALTER TABLE client_packages
    ADD COLUMN sessions_remaining INTEGER
    GENERATED ALWAYS AS (total_sessions - sessions_used - sessions_scheduled) STORED;
    RAISE NOTICE '✅ Created sessions_remaining as GENERATED column';
  END IF;
END $$;

-- STEP 2: Fix all packages with 0 total_sessions
-- ============================================================================
UPDATE client_packages cp
SET total_sessions = COALESCE(p.sessions, 10)
FROM packages p
WHERE cp.package_id = p.id
  AND (cp.total_sessions = 0 OR cp.total_sessions IS NULL);

SELECT '✅ Updated packages with correct session counts' as step2;

-- STEP 3: Fix Nuttapon specifically
-- ============================================================================
UPDATE client_packages cp
SET
  total_sessions = COALESCE(p.sessions, 10),
  status = 'active',
  payment_status = 'paid',
  sessions_used = 0,
  sessions_scheduled = 0
FROM packages p
WHERE cp.package_id = p.id
  AND cp.client_id IN (
    SELECT id FROM users
    WHERE email = 'nattapon@gmail.com'
       OR phone = '0987654321'
  );

SELECT '✅ Fixed Nuttapon packages specifically' as step3;

-- STEP 4: Verify the fix
-- ============================================================================
SELECT
  '🎯 VERIFICATION' as check_type,
  u.full_name,
  u.email,
  cp.package_name,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.status,
  cp.payment_status,
  CASE
    WHEN cp.status = 'active'
      AND cp.payment_status = 'paid'
      AND cp.sessions_remaining > 0
    THEN '✅ WILL SHOW AS ACTIVE IN APP'
    ELSE '❌ STILL HAS ISSUES: ' ||
         CASE
           WHEN cp.status != 'active' THEN 'status=' || cp.status
           WHEN cp.payment_status != 'paid' THEN 'payment=' || cp.payment_status
           WHEN cp.sessions_remaining <= 0 THEN 'sessions=' || COALESCE(cp.sessions_remaining::text, 'NULL')
           ELSE 'unknown'
         END
  END as app_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.email = 'nattapon@gmail.com'
ORDER BY cp.created_at DESC;

-- STEP 5: Show what Flutter will query
-- ============================================================================
SELECT
  '📱 WHAT FLUTTER WILL SEE' as flutter_query,
  cp.*
FROM client_packages cp
WHERE cp.client_id = (SELECT id FROM users WHERE email = 'nattapon@gmail.com' LIMIT 1)
  AND cp.status = 'active'
ORDER BY cp.created_at DESC;

-- ============================================================================
-- FINAL MESSAGE
-- ============================================================================
SELECT '🎉 FIX COMPLETE! Refresh your Flutter app (Ctrl+R)' as final_message;
