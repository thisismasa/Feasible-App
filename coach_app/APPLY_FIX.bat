@echo off
echo ========================================
echo FIX TODAY BOOKING - October 28th
echo ========================================
echo.
echo 🔍 ISSUES FOUND:
echo    1. book_session_with_validation requires 2 hours advance
echo    2. get_available_slots blocks current time slots
echo.
echo 💉 FIX READY:
echo    ✓ Remove 2-hour requirement (allow same-day)
echo    ✓ Allow booking at current time
echo.
echo 📋 APPLYING FIX...
echo.
powershell.exe -Command "Get-Content 'supabase\FIX_TODAY_BOOKING.sql' | Set-Clipboard"
echo ✅ SQL fix copied to clipboard!
echo.
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo 🌐 Supabase SQL Editor opened in browser
echo.
echo ═══════════════════════════════════════
echo NEXT STEPS:
echo ═══════════════════════════════════════
echo 1. In the browser, press Ctrl+V to paste
echo 2. Click the "RUN" button
echo 3. Wait for success message
echo 4. Refresh your Flutter app
echo 5. Try booking today!
echo ═══════════════════════════════════════
echo.
pause
