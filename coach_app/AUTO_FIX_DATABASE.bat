@echo off
title Auto Fix Database - Supabase SQL Editor
color 0A

echo ========================================
echo   AUTO FIX DATABASE
echo ========================================
echo.

REM Copy SQL to clipboard
echo [1/3] Copying SQL fix to clipboard...
type DIAGNOSE_AND_FIX_ALL.sql | clip
echo ✅ SQL copied to clipboard!
echo.

echo [2/3] Opening Supabase SQL Editor...
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo ✅ SQL Editor opened in browser!
echo.

echo ========================================
echo   NEXT STEPS (AUTOMATIC!):
echo ========================================
echo.
echo 1. The SQL is ALREADY in your clipboard
echo 2. In the SQL Editor tab that just opened:
echo    - Click in the SQL editor window
echo    - Press Ctrl+A (select all)
echo    - Press Ctrl+V (paste the fix)
echo    - Click "RUN" button
echo.
echo 3. Wait for execution to complete
echo 4. Check the results at the bottom
echo 5. Refresh your app to see the fix!
echo.
echo ========================================
echo   WHAT THIS FIX DOES:
echo ========================================
echo.
echo ✅ Adds missing 'status' column
echo ✅ Sets all NULL status to 'active'
echo ✅ Fixes remaining_sessions
echo ✅ Fixes expiry_date
echo ✅ Removes orphaned packages
echo ✅ Shows all clients who can book
echo.
echo After running, Khun bie and all clients
echo will show their active packages correctly!
echo.

pause
