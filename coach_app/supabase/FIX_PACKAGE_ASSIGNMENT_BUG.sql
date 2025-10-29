-- ============================================================================
-- FIX: Package Not Showing After Assignment to Client
-- ============================================================================
-- PROBLEM: When you add a package to a new client, it shows "no package"
-- ROOT CAUSE: INNER JOIN fails if package data is missing or mismatched
-- ============================================================================

BEGIN;

-- STEP 1: Check current state
-- ============================================================================
SELECT
  '🔍 DIAGNOSIS: Current Client-Package Status' as step;

SELECT
  cp.id,
  cp.client_id,
  cp.package_id,
  cp.status,
  u.full_name as client_name,
  p.id as package_exists,
  p.name as package_name,
  CASE
    WHEN p.id IS NULL THEN '❌ PACKAGE MISSING - INNER JOIN FAILS!'
    WHEN cp.status IS NULL THEN '❌ STATUS IS NULL'
    WHEN cp.status != 'active' THEN '⚠️ STATUS NOT ACTIVE'
    ELSE '✅ LOOKS GOOD'
  END as diagnosis
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
LEFT JOIN packages p ON cp.package_id = p.id
ORDER BY cp.created_at DESC
LIMIT 10;

-- STEP 2: Fix missing status column (if it doesn't exist)
-- ============================================================================
SELECT
  '🔧 FIX 1: Ensure status column exists' as step;

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- STEP 3: Fix NULL status values
-- ============================================================================
SELECT
  '🔧 FIX 2: Set status to active for NULL values' as step;

UPDATE client_packages
SET status = 'active'
WHERE status IS NULL;

-- STEP 4: Check for orphaned records (packages that don't exist)
-- ============================================================================
SELECT
  '🔧 FIX 3: Find orphaned client_packages' as step;

SELECT
  cp.id as client_package_id,
  cp.client_id,
  cp.package_id,
  '❌ ORPHANED - package does not exist!' as issue
FROM client_packages cp
LEFT JOIN packages p ON cp.package_id = p.id
WHERE p.id IS NULL;

-- Fix: Delete orphaned records OR set them to a default package
-- Option 1: Delete them
DELETE FROM client_packages
WHERE package_id NOT IN (SELECT id FROM packages);

-- STEP 5: Ensure packages have correct schema
-- ============================================================================
SELECT
  '🔧 FIX 4: Verify packages table structure' as step;

-- Check if packages table has required columns
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'packages'
  AND column_name IN ('id', 'name', 'session_count', 'price', 'is_active')
ORDER BY ordinal_position;

-- STEP 6: Fix client_packages table schema
-- ============================================================================
SELECT
  '🔧 FIX 5: Ensure client_packages has all required columns' as step;

-- Add missing columns if they don't exist
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS total_sessions INTEGER DEFAULT 0;

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS remaining_sessions INTEGER DEFAULT 0;

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS sessions_scheduled INTEGER DEFAULT 0;

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS price_paid DECIMAL(10,2);

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS purchase_date TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMPTZ;

-- STEP 7: Create proper function to assign package to client
-- ============================================================================
SELECT
  '🔧 FIX 6: Create safe package assignment function' as step;

CREATE OR REPLACE FUNCTION assign_package_to_client(
  p_client_id UUID,
  p_package_id UUID,
  p_trainer_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_package RECORD;
  v_client_package_id UUID;
  v_expiry_date TIMESTAMPTZ;
BEGIN
  -- Get package details
  SELECT id, name, session_count, price, validity_days
  INTO v_package
  FROM packages
  WHERE id = p_package_id
    AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Package not found or inactive'
    );
  END IF;

  -- Calculate expiry date
  v_expiry_date := NOW() + (v_package.validity_days || ' days')::INTERVAL;

  -- Check if client already has this package
  SELECT id INTO v_client_package_id
  FROM client_packages
  WHERE client_id = p_client_id
    AND package_id = p_package_id
    AND status = 'active';

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Client already has this package assigned'
    );
  END IF;

  -- Create client_package record
  INSERT INTO client_packages (
    client_id,
    package_id,
    total_sessions,
    remaining_sessions,
    sessions_scheduled,
    price_paid,
    purchase_date,
    expiry_date,
    status,
    created_at,
    updated_at
  ) VALUES (
    p_client_id,
    p_package_id,
    v_package.session_count,
    v_package.session_count,  -- All sessions available initially
    0,  -- No sessions scheduled yet
    v_package.price,
    NOW(),
    v_expiry_date,
    'active',
    NOW(),
    NOW()
  ) RETURNING id INTO v_client_package_id;

  -- Create trainer-client relationship if trainer provided
  IF p_trainer_id IS NOT NULL THEN
    INSERT INTO trainer_clients (
      trainer_id,
      client_id,
      status,
      assigned_at
    ) VALUES (
      p_trainer_id,
      p_client_id,
      'active',
      NOW()
    ) ON CONFLICT (trainer_id, client_id) DO NOTHING;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'client_package_id', v_client_package_id,
    'message', 'Package assigned successfully'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql;

-- STEP 8: Create function to safely get client packages
-- ============================================================================
SELECT
  '🔧 FIX 7: Create safe get_client_packages function' as step;

CREATE OR REPLACE FUNCTION get_client_packages(p_client_id UUID)
RETURNS TABLE (
  client_package_id UUID,
  package_id UUID,
  package_name TEXT,
  total_sessions INTEGER,
  remaining_sessions INTEGER,
  sessions_scheduled INTEGER,
  sessions_completed INTEGER,
  price_paid DECIMAL,
  purchase_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  status TEXT,
  can_book BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id as client_package_id,
    p.id as package_id,
    p.name as package_name,
    cp.total_sessions,
    cp.remaining_sessions,
    cp.sessions_scheduled,
    (cp.total_sessions - cp.remaining_sessions - cp.sessions_scheduled) as sessions_completed,
    cp.price_paid,
    cp.purchase_date,
    cp.expiry_date,
    cp.status,
    (cp.remaining_sessions > 0 AND cp.status = 'active' AND cp.expiry_date > NOW()) as can_book
  FROM client_packages cp
  JOIN packages p ON cp.package_id = p.id  -- INNER JOIN ensures package exists
  WHERE cp.client_id = p_client_id
  ORDER BY cp.purchase_date DESC;
END;
$$ LANGUAGE plpgsql;

-- STEP 9: Add indexes for performance
-- ============================================================================
SELECT
  '🔧 FIX 8: Add performance indexes' as step;

CREATE INDEX IF NOT EXISTS idx_client_packages_client_status
ON client_packages(client_id, status)
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_client_packages_package
ON client_packages(package_id);

CREATE INDEX IF NOT EXISTS idx_packages_active
ON packages(is_active)
WHERE is_active = true;

-- STEP 10: Final verification
-- ============================================================================
SELECT
  '✅ VERIFICATION: Check fixed state' as step;

-- Count packages by status
SELECT
  status,
  COUNT(*) as count
FROM client_packages
GROUP BY status;

-- Show recent assignments
SELECT
  u.full_name as client,
  p.name as package,
  cp.status,
  cp.remaining_sessions,
  cp.purchase_date,
  CASE
    WHEN cp.remaining_sessions > 0 AND cp.status = 'active' THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
JOIN packages p ON cp.package_id = p.id
ORDER BY cp.purchase_date DESC
LIMIT 5;

COMMIT;

-- ============================================================================
-- HOW TO USE THE FIX
-- ============================================================================
/*

1. Run this entire SQL file in Supabase SQL Editor

2. To assign a package to a client, use the function:

SELECT * FROM assign_package_to_client(
  p_client_id := 'client-uuid-here',
  p_package_id := 'package-uuid-here',
  p_trainer_id := 'trainer-uuid-here'  -- optional
);

3. To get client packages in your Flutter app, use:

SELECT * FROM get_client_packages('client-uuid-here');

4. Or update your Flutter code to use LEFT JOIN instead of INNER JOIN:

.select('*, packages(*)')  // Use LEFT JOIN, not INNER JOIN

Instead of:

.select('*, packages!inner(*)')  // This fails if package missing!

*/

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- ✅ All client_packages now have status = 'active'
-- ✅ Orphaned records deleted
-- ✅ New safe functions created
-- ✅ Packages will show up correctly after assignment
-- ============================================================================
