-- Verify the booking was created correctly
-- Check session ID: 608ebee7-71fa-43d7-80b3-c8c6d6c059cd

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
  p.package_type
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
WHERE s.id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd';

-- Check if buffer times were calculated
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
  buffer_end
FROM sessions
WHERE id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd';

-- Check if package sessions were decremented
SELECT
  '✅ Package sessions' as check_type,
  package_type,
  total_sessions,
  remaining_sessions,
  sessions_used,
  status
FROM packages
WHERE id IN (SELECT package_id FROM sessions WHERE id = '608ebee7-71fa-43d7-80b3-c8c6d6c059cd');
