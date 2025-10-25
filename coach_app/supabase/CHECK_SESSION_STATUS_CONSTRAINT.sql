-- ============================================================================
-- CHECK: What are the valid session statuses?
-- ============================================================================

SELECT '=== Check sessions table constraints ===' as step;

SELECT
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'sessions'::regclass
  AND contype = 'c'  -- Check constraints
ORDER BY conname;

-- Also check the table definition
SELECT '=== Check sessions table columns ===' as step;

SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'sessions'
  AND table_schema = 'public'
ORDER BY ordinal_position;
