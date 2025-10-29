@echo off
echo ============================================
echo AUTOMATIC SQL FIX EXECUTOR
echo ============================================
echo.
echo Step 1: Opening Supabase SQL Editor...
timeout /t 2 /nobreak > nul
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo.
echo Step 2: Copying FIX_PACKAGE_BOOKING_SYNC.sql to clipboard...
powershell.exe -Command "Get-Content 'FIX_PACKAGE_BOOKING_SYNC.sql' | Set-Clipboard"
timeout /t 1 /nobreak > nul
echo.
echo ✅ SQL READY IN CLIPBOARD!
echo ✅ Browser opened to SQL Editor
echo.
echo ============================================
echo NEXT STEPS:
echo ============================================
echo 1. CLEAR any old SQL in the editor
echo 2. PASTE (Ctrl+V) - you'll get the correct SQL
echo 3. Click RUN button
echo 4. Wait for success messages
echo.
echo This will fix:
echo   - Remove duplicate columns
echo   - Create auto-sync triggers
echo   - Fix all package data
echo   - Use correct column name: sessions
echo.
pause
