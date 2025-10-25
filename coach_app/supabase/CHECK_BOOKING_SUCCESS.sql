-- ============================================================================
-- CHECK: Verify booking was successful and package updated
-- ============================================================================

-- Step 1: Check if session was created
SELECT
  s.id as session_id,
  s.scheduled_start,
  s.scheduled_end,
  s.duration_minutes,
  s.status,
  s.session_type,
  s.location,
  c.full_name as client_name,
  t.full_name as trainer_name
FROM sessions s
JOIN users c ON s.client_id = c.id
JOIN users t ON s.trainer_id = t.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY s.created_at DESC
LIMIT 5;

-- Step 2: Check if package sessions were decremented
SELECT
  cp.id,
  cp.package_name,
  cp.total_sessions,
  cp.used_sessions,
  cp.remaining_sessions,
  c.full_name as client_name
FROM client_packages cp
JOIN users c ON cp.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY cp.created_at DESC;

-- Step 3: Check if today_schedule view exists and shows data
SELECT * FROM today_schedule
WHERE client_name ILIKE '%Nuttapon%'
ORDER BY scheduled_start DESC
LIMIT 5;

-- Step 4: Check if trainer_upcoming_sessions view shows data
SELECT * FROM trainer_upcoming_sessions
WHERE client_name ILIKE '%Nuttapon%'
ORDER BY scheduled_start DESC
LIMIT 5;
