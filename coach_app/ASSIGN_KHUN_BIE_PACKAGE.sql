-- ============================================================================
-- ASSIGN 1800 BAHT PACKAGE TO KHUN BIE
-- ============================================================================
-- Khun bie paid 1800 baht but package was never assigned in database
-- ============================================================================

-- Insert the package assignment with ALL required fields
INSERT INTO client_packages (
  client_id,
  client_name,
  package_id,
  package_name,
  trainer_id,
  status,
  total_sessions,
  remaining_sessions,
  sessions_scheduled,
  price_paid,
  amount_paid,
  payment_method,
  payment_status,
  purchase_date,
  expiry_date,
  is_active,
  created_at,
  updated_at
) VALUES (
  '8ac0fb9e-2966-4a6b-874f-b231dfa3fb2b',  -- Khun bie's client_id
  'Khun Bie',                                  -- client_name
  'ebb9b185-549c-4ab1-bae6-e3f4c358c23a',  -- Single Session 1800 baht package
  'Single Session',                            -- package_name
  (SELECT id FROM users WHERE role = 'trainer' LIMIT 1), -- Get first trainer
  'active',                                    -- status
  1,                                           -- total_sessions
  1,                                           -- remaining_sessions
  0,                                           -- sessions_scheduled
  1800,                                        -- price_paid
  1800,                                        -- amount_paid
  'qr_code',                                   -- payment_method
  'paid',                                      -- payment_status
  NOW(),                                       -- purchase_date
  NOW() + INTERVAL '30 days',                 -- expiry_date (30 days validity)
  true,                                        -- is_active
  NOW(),                                       -- created_at
  NOW()                                        -- updated_at
);

-- Verify the assignment worked
SELECT
  u.full_name as client,
  cp.package_name,
  cp.status,
  cp.total_sessions,
  cp.remaining_sessions,
  cp.price_paid,
  cp.expiry_date,
  CASE
    WHEN cp.remaining_sessions > 0 AND cp.status = 'active' AND cp.expiry_date > NOW()
      THEN '✅ CAN BOOK!'
    ELSE '❌ CANNOT BOOK'
  END as booking_status
FROM client_packages cp
JOIN users u ON cp.client_id = u.id
WHERE u.full_name ILIKE '%bie%'
ORDER BY cp.created_at DESC
LIMIT 1;

-- ============================================================================
-- RESULT: Khun bie should now have an active 1800 baht package
-- ============================================================================
