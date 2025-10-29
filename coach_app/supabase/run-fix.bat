@echo off
echo ============================================
echo EXECUTING SQL FIX AUTOMATICALLY
echo ============================================
echo.
echo Opening Supabase SQL Editor in browser...
timeout /t 2 /nobreak > nul
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo.
echo Copying SQL to clipboard...
type FIX_PACKAGE_BOOKING_SYNC.sql | clip
timeout /t 1 /nobreak > nul
echo.
echo ✅ SQL copied to clipboard!
echo ✅ Browser opened to SQL Editor
echo.
echo Next steps:
echo 1. Paste (Ctrl+V) in the SQL editor
echo 2. Click "RUN" button
echo 3. Verify success messages
echo.
pause
