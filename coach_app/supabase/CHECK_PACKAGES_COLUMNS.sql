-- Check what columns exist in the packages table
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'packages'
ORDER BY ordinal_position;
