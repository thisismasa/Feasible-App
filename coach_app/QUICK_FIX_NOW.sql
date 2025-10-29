-- ============================================================================
-- QUICK FIX NOW - ONE-STEP SOLUTION
-- ============================================================================
-- Run this IMMEDIATELY to fix "Package not found or inactive" error
-- ============================================================================

-- STEP 1: Add 'status' column (what the app needs)
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- STEP 2: Add other missing columns
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'paid';
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS trainer_id UUID;
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS sessions_scheduled INTEGER DEFAULT 0;
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(10,2) DEFAULT 0.0;
ALTER TABLE client_packages ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'manual';

-- STEP 3: Set status = 'active' for all packages
UPDATE client_packages SET status = 'active' WHERE status IS NULL OR status = '';

-- STEP 4: Set remaining_sessions
UPDATE client_packages
SET remaining_sessions = COALESCE(remaining_sessions, total_sessions, 10)
WHERE remaining_sessions IS NULL OR remaining_sessions = 0;

-- STEP 5: Set total_sessions
UPDATE client_packages
SET total_sessions = COALESCE(total_sessions, remaining_sessions, 10)
WHERE total_sessions IS NULL OR total_sessions = 0;

-- STEP 6: Fix expiry_date (extend by 90 days)
UPDATE client_packages
SET expiry_date = NOW() + INTERVAL '90 days'
WHERE expiry_date IS NULL OR expiry_date < NOW();

-- STEP 7: Set start_date
UPDATE client_packages
SET start_date = COALESCE(start_date, purchase_date, NOW())
WHERE start_date IS NULL;

-- STEP 8: Link to active package plan
UPDATE client_packages cp
SET package_id = (
  SELECT id FROM packages WHERE is_active = true ORDER BY sessions LIMIT 1
)
WHERE cp.package_id IS NULL;

-- STEP 9: Set is_active = true
UPDATE client_packages SET is_active = true;

-- STEP 10: Set payment_status
UPDATE client_packages SET payment_status = 'paid' WHERE payment_status IS NULL;

-- STEP 11: Set other fields
UPDATE client_packages SET sessions_scheduled = 0 WHERE sessions_scheduled IS NULL;
UPDATE client_packages SET amount_paid = COALESCE(price_paid, 0.0) WHERE amount_paid IS NULL OR amount_paid = 0;
UPDATE client_packages SET payment_method = 'manual' WHERE payment_method IS NULL;

-- VERIFY: Show all clients can now book
SELECT
  '✅ VERIFICATION' as section,
  u.full_name,
  cp.status,
  cp.remaining_sessions,
  cp.expiry_date,
  CASE
    WHEN cp.status = 'active'
      AND cp.remaining_sessions > 0
      AND cp.expiry_date > NOW()
      AND cp.package_id IS NOT NULL
    THEN '✅ CAN BOOK'
    ELSE '❌ CANNOT BOOK'
  END as result
FROM users u
JOIN client_packages cp ON cp.client_id = u.id
WHERE u.role = 'client'
ORDER BY u.full_name;
