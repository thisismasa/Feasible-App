-- Debug: Check what's in the sessions
SELECT
  s.id,
  s.scheduled_start,
  s.status,
  s.session_type,
  s.location,
  c.full_name as client_name,
  t.full_name as trainer_name,
  p.name as package_name,
  t.id as trainer_id
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
JOIN packages p ON s.package_id = p.id
WHERE s.scheduled_start >= NOW()
ORDER BY s.scheduled_start;

-- Check the view directly
SELECT * FROM trainer_upcoming_sessions
WHERE trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
LIMIT 5;
