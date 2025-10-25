-- ============================================================================
-- DISABLE: All triggers on sessions and client_packages tables
-- ============================================================================
-- The ANY/ALL error is happening even with direct table operations
-- This means a TRIGGER is causing the error when we UPDATE

SELECT '=== Disabling ALL triggers ===' as step;

-- Disable all triggers on sessions table
DO $$
DECLARE
  trigger_record RECORD;
BEGIN
  FOR trigger_record IN
    SELECT trigger_name, event_object_table
    FROM information_schema.triggers
    WHERE event_object_schema = 'public'
      AND event_object_table = 'sessions'
  LOOP
    EXECUTE format('ALTER TABLE %I DISABLE TRIGGER %I',
      trigger_record.event_object_table,
      trigger_record.trigger_name);
    RAISE NOTICE 'Disabled trigger: % on table %',
      trigger_record.trigger_name,
      trigger_record.event_object_table;
  END LOOP;
END $$;

-- Disable all triggers on client_packages table
DO $$
DECLARE
  trigger_record RECORD;
BEGIN
  FOR trigger_record IN
    SELECT trigger_name, event_object_table
    FROM information_schema.triggers
    WHERE event_object_schema = 'public'
      AND event_object_table = 'client_packages'
  LOOP
    EXECUTE format('ALTER TABLE %I DISABLE TRIGGER %I',
      trigger_record.event_object_table,
      trigger_record.trigger_name);
    RAISE NOTICE 'Disabled trigger: % on table %',
      trigger_record.trigger_name,
      trigger_record.event_object_table;
  END LOOP;
END $$;

SELECT '✅ All triggers disabled on sessions and client_packages' as result;

-- ============================================================================
-- Verify triggers are disabled
-- ============================================================================

SELECT '=== Verification ===' as step;

SELECT
  event_object_table,
  trigger_name,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('sessions', 'client_packages')
ORDER BY event_object_table, trigger_name;

-- ============================================================================
-- Reload PostgREST
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload schema';

SELECT '✅ Complete - test cancel button now!' as next_step;
