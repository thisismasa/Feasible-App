-- ============================================================================
-- DEBUG: Find the actual package_id for Nuttapon's package
-- This will show us what ID should be used
-- ============================================================================

-- Step 1: Show Nuttapon's client_packages record
SELECT
  cp.id as client_package_id,
  cp.client_id,
  cp.package_id as template_package_id,
  cp.package_name,
  cp.remaining_sessions,
  c.full_name as client_name
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- Step 2: Check if the package_id exists in packages table
SELECT
  p.id as package_id,
  p.name as package_name,
  p.total_sessions,
  p.is_active
FROM packages p
WHERE p.id IN (
  SELECT cp.package_id
  FROM client_packages cp
  JOIN users c ON cp.client_id = c.id
  WHERE c.full_name ILIKE '%Nuttapon%'
);

-- Step 3: Check foreign key constraint definition
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'sessions'
  AND kcu.column_name = 'package_id';
