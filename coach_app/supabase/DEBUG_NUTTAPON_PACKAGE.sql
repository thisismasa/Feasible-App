-- Debug Nuttapon's package data to understand the ID mismatch
-- This will show the difference between client_packages.id vs packages.id

SELECT
  cp.id as client_package_id,
  cp.client_id,
  cp.package_id as template_package_id,
  cp.package_name,
  cp.remaining_sessions,
  cp.total_sessions,
  cp.status as client_package_status,
  c.full_name as client_name,
  p.id as packages_table_id,
  p.name as packages_table_name,
  p.total_sessions as packages_table_total_sessions
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
LEFT JOIN packages p ON cp.package_id = p.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- This will show what IDs are being used
