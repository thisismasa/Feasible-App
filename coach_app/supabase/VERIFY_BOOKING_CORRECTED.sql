-- Verify the booking was created correctly
-- Check session ID: 608ebee7-71fa-43d7-80b3-c8c6d6c059cd

-- PART 1: Session Details
SELECT
  s.id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.session_type,
  s.location,
  s.client_notes,
  s.status,
  s.buffer_start,
  s.buffer_end,
  s.has_conflicts,
  s.validation_passed,
  c.full_name as client_name,
  t.full_name as trainer_name,
  p.name as package_name
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
WHERE s.id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd';

-- PART 2: Buffer Times Check
SELECT
  '✅ Buffer times' as check_type,
  CASE
    WHEN buffer_start IS NOT NULL AND buffer_end IS NOT NULL
    THEN '✓ Calculated correctly'
    ELSE '✗ Missing buffer times'
  END as status,
  buffer_start,
  scheduled_start,
  scheduled_end,
  buffer_end,
  EXTRACT(EPOCH FROM (scheduled_start - buffer_start)) / 60 as buffer_before_minutes,
  EXTRACT(EPOCH FROM (buffer_end - scheduled_end)) / 60 as buffer_after_minutes
FROM sessions
WHERE id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd';

-- PART 3: Package Information (using correct columns)
SELECT
  '✅ Package info' as check_type,
  p.id,
  p.name,
  p.sessions as total_sessions,
  p.price,
  p.duration_days,
  p.is_active,
  COUNT(s.id) as sessions_booked_count
FROM packages p
LEFT JOIN sessions s ON s.package_id = p.id
WHERE p.id IN (SELECT package_id FROM sessions WHERE id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd')
GROUP BY p.id, p.name, p.sessions, p.price, p.duration_days, p.is_active;
