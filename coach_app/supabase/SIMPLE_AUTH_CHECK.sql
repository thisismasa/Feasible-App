-- Check if user exists in auth.users
SELECT
  'Auth user exists: ' || CASE WHEN COUNT(*) > 0 THEN 'YES ✅' ELSE 'NO ❌' END as status
FROM auth.users
WHERE email = 'masathomardforwork@gmail.com';

-- If result is "NO ❌", then you need to CREATE the user in Supabase Dashboard
-- If result is "YES ✅", then the password is just different - update it in Dashboard
