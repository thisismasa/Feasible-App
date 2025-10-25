-- ============================================================================
-- CHECK WHAT TABLES EXIST IN YOUR DATABASE
-- ============================================================================
-- Run this FIRST to see what tables you have
-- ============================================================================

-- Show all tables in public schema
SELECT
  '📋 YOUR TABLES' as info,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check specifically for sessions-related tables
SELECT
  '🔍 SESSIONS-RELATED TABLES' as info,
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%session%'
ORDER BY table_name;

-- Check for booking-related tables
SELECT
  '🔍 BOOKING-RELATED TABLES' as info,
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%book%'
ORDER BY table_name;

-- List all your tables
SELECT
  '📊 ALL TABLES IN DATABASE' as info,
  STRING_AGG(table_name, ', ' ORDER BY table_name) as all_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
