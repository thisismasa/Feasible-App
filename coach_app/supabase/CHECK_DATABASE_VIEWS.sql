-- ============================================================================
-- CHECK: Database views used by Booking Management screen
-- ============================================================================

-- Check if views exist
SELECT
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'VIEW'
  AND table_name IN ('today_schedule', 'trainer_upcoming_sessions', 'weekly_calendar')
ORDER BY table_name;

-- Show today_schedule view definition
SELECT pg_get_viewdef('today_schedule', true);

-- Show trainer_upcoming_sessions view definition
SELECT pg_get_viewdef('trainer_upcoming_sessions', true);

-- Show weekly_calendar view definition
SELECT pg_get_viewdef('weekly_calendar', true);

-- Test if views return data for Nuttapon's sessions
SELECT 'today_schedule' as view_name, COUNT(*) as row_count
FROM today_schedule
WHERE client_name ILIKE '%Nuttapon%'
UNION ALL
SELECT 'trainer_upcoming_sessions', COUNT(*)
FROM trainer_upcoming_sessions
WHERE client_name ILIKE '%Nuttapon%'
UNION ALL
SELECT 'weekly_calendar', COUNT(*)
FROM weekly_calendar
WHERE client_name ILIKE '%Nuttapon%';

-- ============================================================================
-- WHAT THIS CHECKS:
-- ============================================================================
-- 1. Do the views exist?
-- 2. What are their definitions (might have wrong JOINs)?
-- 3. Do they return data for Nuttapon's booked sessions?
-- 4. If row_count = 0, the views are broken or filtering incorrectly
-- ============================================================================
