-- Find all versions of book_session_with_validation
SELECT
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  'DROP FUNCTION IF EXISTS ' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ') CASCADE;' as drop_statement
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'book_session_with_validation'
  AND n.nspname = 'public';

-- Find all versions of get_available_slots
SELECT
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  'DROP FUNCTION IF EXISTS ' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ') CASCADE;' as drop_statement
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'get_available_slots'
  AND n.nspname = 'public';
