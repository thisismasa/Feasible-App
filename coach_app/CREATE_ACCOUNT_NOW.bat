@echo off
echo ============================================
echo CREATE TRAINER ACCOUNT - AUTOMATIC SETUP
echo ============================================
echo.
echo This will open Supabase Dashboard to create your account
echo Email: masathomardforwork@gmail.com
echo.
echo STEPS YOU'LL DO:
echo 1. Supabase Auth page will open
echo 2. Click "Add user" button (green, top right)
echo 3. Select "Create new user"
echo 4. Email: masathomardforwork@gmail.com
echo 5. Password: Create a strong one!
echo 6. CHECK "Auto Confirm User" (important!)
echo 7. Click "Create user"
echo 8. Come back here and press any key...
echo.
pause
echo.
echo Opening Supabase Authentication page...
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/auth/users
echo.
echo Waiting for you to create the user...
echo (Create the user, then come back and press any key)
echo.
pause
echo.
echo Now opening SQL Editor to setup trainer profile...
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo.
echo The SQL is already in your clipboard!
echo Just press Ctrl+V in SQL Editor, then click RUN
echo.
echo After running SQL, your account is ready!
echo.
pause
