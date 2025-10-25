-- Check what columns exist in client_packages table
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'client_packages'
ORDER BY ordinal_position;
