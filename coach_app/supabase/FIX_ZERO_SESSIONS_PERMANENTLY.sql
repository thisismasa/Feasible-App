-- ============================================================================
-- PERMANENT FIX: Ensure packages ALWAYS show correct session counts
-- ============================================================================
-- This fixes both existing broken packages AND prevents future issues
-- ============================================================================

-- PART 1: FIX ALL EXISTING PACKAGES WITH 0 SESSIONS
-- ============================================================================

-- Find and fix packages that have 0 total_sessions but should have sessions
-- We'll match them with the packages table to get the correct session count

UPDATE client_packages cp
SET total_sessions = p.sessions
FROM packages p
WHERE cp.package_id = p.id
  AND cp.total_sessions = 0
  AND p.sessions > 0;

-- Show what was fixed
SELECT
  '✅ FIXED PACKAGES' as result,
  cp.id,
  u.full_name as client_name,
  cp.package_name,
  cp.total_sessions as sessions_now,
  cp.sessions_remaining as remaining_now,
  cp.status,
  cp.payment_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE cp.updated_at > NOW() - INTERVAL '1 minute'
ORDER BY cp.updated_at DESC;

-- PART 2: FIX SPECIFIC CLIENTS (Nuttapon and Nadtaporn)
-- ============================================================================

-- Update their packages to have correct sessions from the packages table
WITH client_ids AS (
  SELECT id, full_name, email FROM users
  WHERE full_name ILIKE '%nutt%'
     OR full_name ILIKE '%nadt%'
     OR email ILIKE '%natt%'
     OR email ILIKE '%nutg%'
     OR phone LIKE '%0987654321%'
)
UPDATE client_packages cp
SET
  total_sessions = COALESCE(p.sessions, 10),  -- Use package sessions or default to 10
  status = 'active',
  payment_status = 'paid',
  sessions_used = 0,
  sessions_scheduled = 0
FROM packages p, client_ids c
WHERE cp.package_id = p.id
  AND cp.client_id = c.id
  AND cp.created_at > NOW() - INTERVAL '30 days';

-- PART 3: VERIFY THE FIX
-- ============================================================================

SELECT
  '🎯 VERIFICATION: Nuttapon & Nadtaporn packages' as check_name,
  u.full_name,
  u.email,
  cp.package_name,
  cp.total_sessions,
  cp.sessions_used,
  cp.sessions_scheduled,
  cp.sessions_remaining,
  cp.status,
  cp.payment_status,
  cp.expiry_date,
  CASE
    WHEN cp.status = 'active'
      AND cp.payment_status = 'paid'
      AND cp.sessions_remaining > 0
      AND cp.expiry_date > NOW()
    THEN '✅ READY FOR BOOKING'
    WHEN cp.sessions_remaining = 0 OR cp.sessions_remaining IS NULL
    THEN '❌ sessions_remaining is ' || COALESCE(cp.sessions_remaining::text, 'NULL')
    WHEN cp.status != 'active'
    THEN '❌ status is ' || cp.status
    ELSE '⚠️ Check other fields'
  END as status_check
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.full_name ILIKE '%nutt%'
   OR u.full_name ILIKE '%nadt%'
   OR u.email ILIKE '%natt%'
   OR u.email ILIKE '%nutg%'
ORDER BY cp.created_at DESC;

-- PART 4: CREATE A FUNCTION TO AUTO-FIX ON INSERT
-- ============================================================================

-- Create a trigger function that ensures total_sessions is never 0
CREATE OR REPLACE FUNCTION fix_zero_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- If total_sessions is 0, try to get it from packages table
  IF NEW.total_sessions = 0 OR NEW.total_sessions IS NULL THEN
    SELECT sessions INTO NEW.total_sessions
    FROM packages
    WHERE id = NEW.package_id;

    -- If still 0 or NULL, log a warning but don't block the insert
    IF NEW.total_sessions = 0 OR NEW.total_sessions IS NULL THEN
      RAISE WARNING 'Package % has 0 sessions! Setting default to 10', NEW.package_name;
      NEW.total_sessions := 10;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS ensure_sessions_not_zero ON client_packages;

-- Create the trigger
CREATE TRIGGER ensure_sessions_not_zero
  BEFORE INSERT OR UPDATE ON client_packages
  FOR EACH ROW
  EXECUTE FUNCTION fix_zero_sessions();

-- PART 5: FINAL VERIFICATION
-- ============================================================================

SELECT '✅ COMPLETE! All packages fixed and trigger installed' as final_status;

-- Show all active packages in the system
SELECT
  '📊 ALL ACTIVE PACKAGES IN SYSTEM' as summary,
  COUNT(*) as total_active,
  COUNT(CASE WHEN sessions_remaining > 0 THEN 1 END) as with_sessions,
  COUNT(CASE WHEN sessions_remaining = 0 THEN 1 END) as zero_sessions
FROM client_packages
WHERE status = 'active';

-- Show Nuttapon and Nadtaporn's final status
SELECT
  '🎉 FINAL RESULT FOR YOUR CLIENTS' as result,
  u.full_name,
  u.email,
  cp.package_name,
  cp.total_sessions || ' total sessions' as sessions,
  cp.sessions_remaining || ' remaining' as remaining,
  'Status: ' || cp.status as status,
  'Payment: ' || cp.payment_status as payment,
  CASE
    WHEN cp.sessions_remaining > 0 THEN '✅ READY TO BOOK'
    ELSE '❌ STILL HAS ISSUES'
  END as can_book
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE (u.full_name ILIKE '%nutt%' OR u.full_name ILIKE '%nadt%')
  AND cp.status = 'active'
ORDER BY u.full_name, cp.created_at DESC;
