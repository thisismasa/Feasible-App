-- ============================================================================
-- VERIFY: Check if auto_sync_package_sessions trigger is working
-- ============================================================================

-- Check if trigger exists
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'auto_sync_package_sessions';

-- Check trigger function
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'sync_package_remaining_sessions';
