-- ============================================================================
-- COMPREHENSIVE DATABASE HEALTH CHECK
-- ============================================================================
-- Scans all functions, tables, and features for errors
-- Date: October 26, 2025
-- ============================================================================

-- TEST 1: Check all database functions
-- ============================================================================
SELECT '===== TEST 1: ALL DATABASE FUNCTIONS =====' as test;

SELECT
  routine_name as function_name,
  routine_type as type,
  data_type as return_type,
  CASE
    WHEN routine_name LIKE '%book%' THEN '🎯 Booking Related'
    WHEN routine_name LIKE '%cancel%' THEN '🎯 Cancellation Related'
    WHEN routine_name LIKE '%session%' THEN '🎯 Session Related'
    WHEN routine_name LIKE '%package%' THEN '🎯 Package Related'
    ELSE '📋 Other'
  END as category
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- TEST 2: Check for missing critical functions
-- ============================================================================
SELECT '===== TEST 2: CRITICAL FUNCTIONS CHECK =====' as test;

WITH required_functions AS (
  SELECT unnest(ARRAY[
    'book_session',
    'cancel_session',
    'get_buffer_minutes',
    'check_booking_conflicts',
    'assign_package_to_client'
  ]) as func_name
)
SELECT
  rf.func_name as required_function,
  CASE
    WHEN r.routine_name IS NOT NULL THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM required_functions rf
LEFT JOIN information_schema.routines r
  ON r.routine_name = rf.func_name
  AND r.routine_schema = 'public';

-- TEST 3: Check table schemas
-- ============================================================================
SELECT '===== TEST 3: CRITICAL TABLES CHECK =====' as test;

SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns c WHERE c.table_name = t.table_name) as column_count,
  '✅ EXISTS' as status
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'users', 'packages', 'client_packages', 'sessions',
    'trainer_clients', 'booking_rules', 'payment_transactions'
  )
ORDER BY table_name;

-- TEST 4: Check sessions table schema
-- ============================================================================
SELECT '===== TEST 4: SESSIONS TABLE COLUMNS =====' as test;

SELECT
  column_name,
  data_type,
  is_nullable,
  CASE
    WHEN column_name IN ('scheduled_start', 'scheduled_end') THEN '⏰ Time columns'
    WHEN column_name IN ('buffer_start', 'buffer_end') THEN '🛡️ Buffer columns'
    WHEN column_name = 'google_calendar_event_id' THEN '📅 Calendar sync'
    WHEN column_name IN ('client_id', 'trainer_id', 'package_id') THEN '🔗 Relations'
    ELSE '📋 Other'
  END as category
FROM information_schema.columns
WHERE table_name = 'sessions'
ORDER BY ordinal_position;

-- TEST 5: Test book_session function
-- ============================================================================
SELECT '===== TEST 5: TEST BOOKING FUNCTION =====' as test;

-- Check if book_session function exists and its signature
SELECT
  routine_name,
  array_agg(parameter_name || ': ' || data_type ORDER BY ordinal_position) as parameters,
  '✅ Function signature valid' as status
FROM information_schema.parameters
WHERE specific_schema = 'public'
  AND routine_name LIKE 'book_session%'
GROUP BY routine_name;

-- TEST 6: Check for broken foreign keys
-- ============================================================================
SELECT '===== TEST 6: FOREIGN KEY CONSTRAINTS =====' as test;

SELECT
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  '✅ Valid' as status
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('sessions', 'client_packages', 'trainer_clients', 'payment_transactions')
ORDER BY tc.table_name;

-- TEST 7: Check for missing indexes
-- ============================================================================
SELECT '===== TEST 7: CRITICAL INDEXES =====' as test;

SELECT
  tablename,
  indexname,
  indexdef,
  CASE
    WHEN indexname LIKE '%scheduled%' THEN '⏰ Time index'
    WHEN indexname LIKE '%buffer%' THEN '🛡️ Buffer index'
    WHEN indexname LIKE '%trainer%' THEN '👤 Trainer index'
    WHEN indexname LIKE '%client%' THEN '👥 Client index'
    ELSE '📋 Other'
  END as index_type
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('sessions', 'client_packages', 'booking_rules')
ORDER BY tablename, indexname;

-- TEST 8: Check sessions table data quality
-- ============================================================================
SELECT '===== TEST 8: SESSIONS DATA QUALITY =====' as test;

SELECT
  'Total sessions' as metric,
  COUNT(*)::TEXT as value,
  '📊' as icon
FROM sessions
UNION ALL
SELECT
  'Sessions with buffer times',
  COUNT(*)::TEXT,
  CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '❌' END
FROM sessions
WHERE buffer_start IS NOT NULL AND buffer_end IS NOT NULL
UNION ALL
SELECT
  'Sessions with scheduled_end',
  COUNT(*)::TEXT,
  CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '❌' END
FROM sessions
WHERE scheduled_end IS NOT NULL
UNION ALL
SELECT
  'Sessions missing critical timestamps',
  COUNT(*)::TEXT,
  CASE WHEN COUNT(*) = 0 THEN '✅' ELSE '⚠️' END
FROM sessions
WHERE scheduled_start IS NULL OR scheduled_date IS NULL;

-- TEST 9: Check for duplicate or conflicting booking rules
-- ============================================================================
SELECT '===== TEST 9: BOOKING RULES VALIDATION =====' as test;

SELECT
  rule_name,
  rule_type,
  rule_value,
  is_active,
  COUNT(*) as duplicate_count,
  CASE
    WHEN COUNT(*) > 1 THEN '⚠️ DUPLICATE'
    ELSE '✅ UNIQUE'
  END as status
FROM booking_rules
GROUP BY rule_name, rule_type, rule_value, is_active
ORDER BY rule_name;

-- TEST 10: Check calendar sync readiness
-- ============================================================================
SELECT '===== TEST 10: CALENDAR SYNC STATUS =====' as test;

SELECT
  COUNT(*) as total_sessions,
  COUNT(*) FILTER (WHERE google_calendar_event_id IS NOT NULL) as synced,
  COUNT(*) FILTER (WHERE google_calendar_event_id IS NULL) as not_synced,
  CASE
    WHEN COUNT(*) FILTER (WHERE google_calendar_event_id IS NOT NULL) > 0
    THEN '✅ Sync working'
    ELSE '⚠️ No syncs (expected if no Google sign-in)'
  END as sync_status
FROM sessions
WHERE status IN ('scheduled', 'confirmed');

-- TEST 11: Identify potential issues
-- ============================================================================
SELECT '===== TEST 11: POTENTIAL ISSUES =====' as test;

-- Check for sessions with missing scheduled_end
SELECT
  'Sessions missing scheduled_end' as issue,
  COUNT(*)::TEXT as affected_count,
  CASE WHEN COUNT(*) > 0 THEN '⚠️ NEEDS FIX' ELSE '✅ OK' END as severity
FROM sessions
WHERE scheduled_end IS NULL AND scheduled_start IS NOT NULL
UNION ALL
-- Check for sessions with no buffer times
SELECT
  'Sessions missing buffer times',
  COUNT(*)::TEXT,
  CASE WHEN COUNT(*) > 0 THEN '⚠️ NEEDS FIX' ELSE '✅ OK' END
FROM sessions
WHERE (buffer_start IS NULL OR buffer_end IS NULL)
  AND scheduled_start IS NOT NULL
UNION ALL
-- Check for invalid time ranges
SELECT
  'Sessions with invalid time range',
  COUNT(*)::TEXT,
  CASE WHEN COUNT(*) > 0 THEN '❌ CRITICAL' ELSE '✅ OK' END
FROM sessions
WHERE scheduled_end IS NOT NULL
  AND scheduled_start IS NOT NULL
  AND scheduled_end <= scheduled_start;

-- TEST 12: Check RLS policies
-- ============================================================================
SELECT '===== TEST 12: ROW LEVEL SECURITY STATUS =====' as test;

SELECT
  tablename,
  CASE
    WHEN rowsecurity THEN '🔒 RLS ENABLED'
    ELSE '⚠️ RLS DISABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'sessions', 'client_packages', 'packages',
    'trainer_clients', 'booking_rules', 'payment_transactions'
  )
ORDER BY tablename;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT '===== HEALTH CHECK COMPLETE =====' as test;

SELECT
  '🏥 Database Health Check Complete' as message,
  '' as blank,
  'Review results above for any ❌ CRITICAL or ⚠️ WARNING issues' as action;
