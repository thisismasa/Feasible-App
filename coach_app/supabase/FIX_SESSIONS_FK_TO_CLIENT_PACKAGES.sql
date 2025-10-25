-- ============================================================================
-- FIX: Change sessions.package_id to reference client_packages instead
-- Purpose: Fix foreign key constraint error
-- ============================================================================

-- Option 1: Drop the old foreign key constraint (if it exists)
ALTER TABLE sessions
DROP CONSTRAINT IF EXISTS sessions_package_id_fkey CASCADE;

-- Option 2: Add new foreign key to client_packages table
-- This makes more sense because sessions belong to a client's package instance
ALTER TABLE sessions
ADD CONSTRAINT sessions_client_package_id_fkey
FOREIGN KEY (package_id)
REFERENCES client_packages(id)
ON DELETE RESTRICT;

-- Verify the change
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

-- ============================================================================
-- WHAT THIS DOES:
-- ============================================================================
-- Changes sessions.package_id foreign key from:
--   packages.id (template)
-- To:
--   client_packages.id (instance)
--
-- This makes logical sense because:
-- - A session belongs to a specific client's package purchase
-- - Not to the generic package template
-- ============================================================================
