-- Check what status the booked sessions actually have
SELECT
  id,
  scheduled_start,
  status,
  session_type,
  location,
  client_id,
  trainer_id,
  package_id
FROM sessions
WHERE trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
  AND scheduled_start >= NOW()
ORDER BY scheduled_start;

-- Check all statuses in use
SELECT
  status,
  COUNT(*) as count
FROM sessions
WHERE trainer_id = '72f779ab-e255-44f6-8f27-81f17bb24921'
GROUP BY status;
