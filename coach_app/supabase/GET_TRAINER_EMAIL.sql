-- Get the email for the trainer we've been using
SELECT
  id,
  email,
  full_name,
  role
FROM public.users
WHERE id = '72f779ab-e255-44f6-8f27-81f17bb24921';

-- Also check all trainers
SELECT
  id,
  email,
  full_name,
  role,
  created_at
FROM public.users
WHERE role = 'trainer'
ORDER BY created_at DESC;
