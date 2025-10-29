@echo off
echo ============================================
echo VERIFICATION SQL - CHECK IF FIX WORKED
echo ============================================
echo.
echo Opening Supabase SQL Editor...
timeout /t 1 /nobreak > nul
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo.
echo Copying verification SQL to clipboard...
powershell.exe -Command "Get-Content 'VERIFY_PACKAGE_FIX.sql' | Set-Clipboard"
timeout /t 1 /nobreak > nul
echo.
echo ✅ Verification SQL copied to clipboard!
echo ✅ Browser opened to SQL Editor
echo.
echo ============================================
echo INSTRUCTIONS:
echo ============================================
echo 1. Paste (Ctrl+V) in SQL editor
echo 2. Click RUN
echo 3. Check results:
echo    - All checks should show ✅ PASS
echo    - You'll see your current packages
echo    - You'll see all triggers created
echo.
pause
