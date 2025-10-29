@echo off
echo ============================================
echo DEPLOY: Prevent Advance Session Completion
echo ============================================
echo.
echo This will:
echo 1. Copy SQL to clipboard
echo 2. Open Supabase SQL Editor
echo.
echo Then you:
echo 1. Paste (Ctrl+V) in SQL Editor
echo 2. Click "Run" to execute
echo.
pause

REM Copy SQL to clipboard
powershell -Command "Get-Content 'supabase\PREVENT_ADVANCE_COMPLETION.sql' | Set-Clipboard"
echo ✓ SQL copied to clipboard!
echo.

REM Open Supabase SQL Editor
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new

echo.
echo ✓ Supabase SQL Editor opened
echo.
echo NEXT STEPS:
echo 1. Paste the SQL (Ctrl+V)
echo 2. Click "Run"
echo 3. Check the results
echo.
pause
