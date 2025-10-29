-- ============================================================================
-- FIX ALL EXISTING CLIENTS WITHOUT PACKAGES
-- ============================================================================
-- Assigns default "No Package" to all clients who don't have any packages
-- ============================================================================

-- Step 1: Show clients without packages
-- ============================================================================
SELECT '📊 CLIENTS WITHOUT PACKAGES:' as info;

SELECT
  u.id,
  u.full_name,
  u.email,
  u.created_at,
  '❌ NO PACKAGE' as status
FROM users u
WHERE u.role = 'client'
  AND u.id NOT IN (
    SELECT DISTINCT client_id
    FROM client_packages
    WHERE client_id IS NOT NULL
  )
ORDER BY u.created_at DESC;

-- Step 2: Count them
-- ============================================================================
SELECT
  COUNT(*) as clients_without_packages
FROM users u
WHERE u.role = 'client'
  AND u.id NOT IN (
    SELECT DISTINCT client_id
    FROM client_packages
    WHERE client_id IS NOT NULL
  );

-- Step 3: Ensure "No Package" exists
-- ============================================================================
DO $$
DECLARE
  v_default_package_id UUID;
  v_trainer_id UUID;
  v_client RECORD;
  v_count INTEGER := 0;
BEGIN
  -- Get first trainer
  SELECT id INTO v_trainer_id
  FROM users
  WHERE role = 'trainer'
  LIMIT 1;

  -- Find or create "No Package"
  SELECT id INTO v_default_package_id
  FROM packages
  WHERE name = 'No Package'
    AND is_active = true
  LIMIT 1;

  IF v_default_package_id IS NULL THEN
    INSERT INTO packages (
      name,
      description,
      session_count,
      price,
      validity_days,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      'No Package',
      'Default package for existing clients - Please assign a real package',
      0,
      0,
      30,
      true,
      NOW(),
      NOW()
    ) RETURNING id INTO v_default_package_id;

    RAISE NOTICE '✅ Created "No Package" with ID: %', v_default_package_id;
  ELSE
    RAISE NOTICE '✅ Found existing "No Package" with ID: %', v_default_package_id;
  END IF;

  -- Step 4: Assign package to all clients without one
  FOR v_client IN
    SELECT u.id, u.full_name
    FROM users u
    WHERE u.role = 'client'
      AND u.id NOT IN (
        SELECT DISTINCT client_id
        FROM client_packages
        WHERE client_id IS NOT NULL
      )
  LOOP
    INSERT INTO client_packages (
      client_id,
      package_id,
      package_name,
      trainer_id,
      status,
      total_sessions,
      remaining_sessions,
      used_sessions,
      sessions_scheduled,
      price_paid,
      amount_paid,
      payment_method,
      payment_status,
      is_active,
      is_subscription,
      purchase_date,
      created_at,
      updated_at
    ) VALUES (
      v_client.id,
      v_default_package_id,
      'No Package',
      v_trainer_id,
      'active',
      0,
      0,
      0,
      0,
      0,
      0,
      'none',
      'pending',
      true,
      false,
      NOW(),
      NOW(),
      NOW()
    );

    v_count := v_count + 1;
    RAISE NOTICE '✅ Assigned package to: % (ID: %)', v_client.full_name, v_client.id;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '  ✅ FIXED % CLIENTS', v_count;
  RAISE NOTICE '========================================';

END $$;

-- Step 5: Verify all clients now have packages
-- ============================================================================
SELECT '📊 VERIFICATION:' as info;

SELECT
  COUNT(*) as total_clients,
  (SELECT COUNT(*) FROM users WHERE role = 'client') as clients_in_db,
  (SELECT COUNT(DISTINCT client_id) FROM client_packages) as clients_with_packages,
  CASE
    WHEN COUNT(*) = (SELECT COUNT(DISTINCT client_id) FROM client_packages)
      THEN '✅ ALL CLIENTS HAVE PACKAGES!'
    ELSE '❌ SOME CLIENTS STILL MISSING PACKAGES'
  END as status
FROM users
WHERE role = 'client';

-- Step 6: Show all clients with their packages
-- ============================================================================
SELECT '📋 ALL CLIENTS WITH PACKAGES:' as info;

SELECT
  u.full_name as client,
  u.email,
  cp.package_name,
  cp.status,
  cp.remaining_sessions,
  cp.payment_status,
  CASE
    WHEN cp.package_name = 'No Package' THEN '⚠️  NEEDS REAL PACKAGE'
    WHEN cp.remaining_sessions > 0 AND cp.status = 'active' THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM users u
LEFT JOIN client_packages cp ON u.id = cp.client_id
WHERE u.role = 'client'
ORDER BY u.created_at DESC;

-- ============================================================================
-- RESULT:
-- ============================================================================
-- ✅ All existing clients now have a default "No Package"
-- ✅ They will show up in "Select Client for Booking"
-- ✅ PT can then assign them a real package
-- ============================================================================
