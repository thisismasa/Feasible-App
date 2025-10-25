-- ============================================================================
-- FIX CLIENT_PACKAGES TABLE SCHEMA
-- ============================================================================
-- This adds the missing 'status' column to client_packages table
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================================

-- Add missing status column to client_packages
ALTER TABLE client_packages
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- Set default values for existing records
UPDATE client_packages
SET status = 'active'
WHERE status IS NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_client_packages_status
ON client_packages(status);

-- Verify the column exists
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
  AND column_name = 'status';

-- Show sample data to confirm
SELECT
  id,
  client_id,
  package_id,
  status,
  created_at
FROM client_packages
LIMIT 5;

-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
-- column_name: status
-- data_type: character varying
-- column_default: 'active'::character varying
--
-- NOW YOUR APP CAN LOAD CLIENT PACKAGES!
-- ============================================================================
