-- ====================================
-- FIX OCT 27 BOOKING ISSUES
-- ====================================
-- Problem: Client packages missing critical fields causing booking failures
-- Solution: Update all packages with proper configuration
--
-- Date: Oct 27, 2025
-- ====================================

BEGIN;

-- 1. First, let's check current state
SELECT
  'BEFORE FIX' as status,
  id,
  client_id,
  package_id,
  sessions_remaining,
  total_sessions,
  start_date,
  end_date,
  min_advance_hours,
  allow_same_day,
  status
FROM client_packages
WHERE status = 'active'
LIMIT 5;

-- 2. Update all active client packages with missing fields
UPDATE client_packages
SET
  -- Set sessions_remaining to total_sessions if NULL
  sessions_remaining = COALESCE(sessions_remaining, total_sessions),

  -- Set start_date to today if NULL
  start_date = COALESCE(start_date, CURRENT_DATE),

  -- Set end_date to 90 days from start_date if NULL
  end_date = COALESCE(end_date, COALESCE(start_date, CURRENT_DATE) + INTERVAL '90 days'),

  -- Set booking rules to allow same-day booking
  min_advance_hours = COALESCE(min_advance_hours, 0),
  max_advance_days = COALESCE(max_advance_days, 30),
  allow_same_day = COALESCE(allow_same_day, true),

  -- Ensure status is active
  status = 'active',

  -- Update timestamp
  updated_at = NOW()
WHERE status = 'active';

-- 3. Check results after fix
SELECT
  'AFTER FIX' as status,
  id,
  client_id,
  package_id,
  sessions_remaining,
  total_sessions,
  start_date,
  end_date,
  min_advance_hours,
  max_advance_days,
  allow_same_day,
  status
FROM client_packages
WHERE status = 'active'
LIMIT 5;

-- 4. Verify no sessions are blocking Oct 27
SELECT
  'SESSIONS ON OCT 27' as check_type,
  COUNT(*) as count
FROM sessions
WHERE scheduled_start >= '2025-10-27 00:00:00'
  AND scheduled_start < '2025-10-28 00:00:00';

-- 5. Summary report
SELECT
  'SUMMARY' as report,
  COUNT(*) as total_active_packages,
  COUNT(*) FILTER (WHERE sessions_remaining > 0) as packages_with_sessions,
  COUNT(*) FILTER (WHERE min_advance_hours = 0) as packages_allow_immediate,
  COUNT(*) FILTER (WHERE allow_same_day = true) as packages_allow_same_day
FROM client_packages
WHERE status = 'active';

COMMIT;

-- ====================================
-- VERIFICATION QUERIES
-- ====================================

-- Run these after the fix to verify everything works:

-- Check if a specific client can book on Oct 27
SELECT
  cp.id as package_id,
  cp.sessions_remaining,
  cp.min_advance_hours,
  cp.allow_same_day,
  cp.start_date,
  cp.end_date,
  CASE
    WHEN cp.sessions_remaining > 0
      AND '2025-10-27' >= cp.start_date
      AND '2025-10-27' <= cp.end_date
      AND cp.allow_same_day = true
    THEN 'CAN BOOK'
    ELSE 'CANNOT BOOK'
  END as booking_status
FROM client_packages cp
WHERE cp.status = 'active'
  AND cp.client_id = (SELECT id FROM users WHERE role = 'client' LIMIT 1)
LIMIT 1;

-- ====================================
-- EXPECTED RESULTS:
-- ====================================
-- ✅ All packages should have:
--    - sessions_remaining = total_sessions (or current value if set)
--    - start_date = today or existing date
--    - end_date = start_date + 90 days
--    - min_advance_hours = 0 (allow immediate booking)
--    - max_advance_days = 30
--    - allow_same_day = true
--
-- ✅ No sessions blocking Oct 27
-- ✅ Clients should be able to book on Oct 27
-- ====================================
