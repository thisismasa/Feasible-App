-- ============================================================================
-- INVESTIGATE: Why do views return 0 rows when sessions exist?
-- ============================================================================

-- Step 1: Verify sessions exist in the base table
SELECT
  s.id,
  s.client_id,
  s.trainer_id,
  s.package_id,
  s.scheduled_start,
  s.scheduled_end,
  s.status,
  s.created_at,
  c.full_name as client_name,
  c.id as client_uuid,
  t.full_name as trainer_name,
  t.id as trainer_uuid
FROM sessions s
LEFT JOIN users c ON s.client_id = c.id
LEFT JOIN users t ON s.trainer_id = t.id
WHERE c.full_name ILIKE '%Nuttapon%'
ORDER BY s.created_at DESC;

-- Step 2: Check what the views expect (look at actual view definition)
-- Get today_schedule view definition
SELECT pg_get_viewdef('today_schedule'::regclass, true);

-- Step 3: Check what columns the views are selecting
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'today_schedule'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 4: Try to manually query like the view does (to see why it fails)
-- This will help us understand what's wrong
SELECT
  s.*,
  c.full_name as client_name,
  c.email as client_email
FROM sessions s
JOIN users c ON s.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND s.status IN ('scheduled', 'confirmed')
  AND DATE(s.scheduled_start) = CURRENT_DATE;

-- Step 5: Check upcoming sessions (any future date)
SELECT
  s.*,
  c.full_name as client_name,
  c.email as client_email
FROM sessions s
JOIN users c ON s.client_id = c.id
WHERE c.full_name ILIKE '%Nuttapon%'
  AND s.status IN ('scheduled', 'confirmed')
  AND s.scheduled_start >= NOW()
ORDER BY s.scheduled_start;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- Query 1: Should show Nuttapon's session(s) with all fields
-- Query 2: Will show the view definition (might reveal wrong JOINs)
-- Query 3: List columns the view exposes
-- Query 4: Check if date filter is too restrictive (today only?)
-- Query 5: Should show future sessions regardless of date
-- ============================================================================
