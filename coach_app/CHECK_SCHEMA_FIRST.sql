-- ============================================
-- STEP 1: CHECK DATABASE SCHEMA
-- ============================================
-- Run this first to see the actual column names
-- https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
-- ============================================

-- Check client_packages table columns
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
ORDER BY ordinal_position;

-- Check packages table columns
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'packages'
ORDER BY ordinal_position;

-- Show sample data from client_packages
SELECT * FROM client_packages LIMIT 3;

-- Show sample data from packages
SELECT * FROM packages LIMIT 3;
