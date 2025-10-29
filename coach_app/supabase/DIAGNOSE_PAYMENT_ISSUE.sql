-- ============================================================================
-- DIAGNOSE PAYMENT ISSUE - Complete Check
-- ============================================================================

-- Check 1: Does payment_transactions table exist and have correct schema?
SELECT '========== CHECK 1: payment_transactions table ==========' as check;
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- Check 2: What foreign key constraints does it have?
SELECT '========== CHECK 2: Foreign Key Constraints ==========' as check;
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'payment_transactions'
  AND tc.constraint_type = 'FOREIGN KEY';

-- Check 3: Does packages table exist and have data?
SELECT '========== CHECK 3: packages table (templates) ==========' as check;
SELECT
  id,
  name,
  sessions as session_count,
  price,
  duration_days as validity_days
FROM packages
LIMIT 5;

-- Check 4: Does client_packages table exist?
SELECT '========== CHECK 4: client_packages table ==========' as check;
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'client_packages'
ORDER BY ordinal_position
LIMIT 10;

-- Check 5: Check the specific client mentioned in error
SELECT '========== CHECK 5: Client Poon ==========' as check;
SELECT
  id,
  email,
  full_name,
  role
FROM users
WHERE id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41';

-- Check 6: Does this client have any packages already?
SELECT '========== CHECK 6: Poons existing packages ==========' as check;
SELECT
  id,
  package_name,
  total_sessions,
  sessions_used,
  remaining_sessions,
  status,
  is_active,
  purchase_date,
  expiry_date
FROM client_packages
WHERE client_id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41';

-- Check 7: Try a test insert (will fail if something's wrong)
SELECT '========== CHECK 7: Test Insert (DRY RUN) ==========' as check;
SELECT 'This would insert:' as info;
SELECT
  'ac6b34af-77e4-41c0-a0de-59ef190fab41' as client_id,
  '72f779ab-e255-44f6-8f27-81f17bb24921' as trainer_id,
  (SELECT id FROM packages LIMIT 1) as package_id,
  'promptpay' as payment_method,
  'package_purchase' as transaction_type,
  1000.00 as amount;

-- Final summary
SELECT '========== SUMMARY ==========' as check;
SELECT
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'payment_transactions') as payment_table_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'packages') as packages_table_exists,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'client_packages') as client_packages_table_exists,
  (SELECT COUNT(*) FROM packages) as total_package_templates,
  (SELECT COUNT(*) FROM users WHERE id = 'ac6b34af-77e4-41c0-a0de-59ef190fab41') as client_exists;
