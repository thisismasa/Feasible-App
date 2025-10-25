@echo off
echo.
echo ========================================
echo   Opening Coach App UI Mockup
echo ========================================
echo.
echo This will open the visual mockup in your browser...
echo.

start "" "%~dp0UI_MOCKUP.html"

echo.
echo Mockup should now be open in your browser!
echo.
echo You will see 6 phone screens showing:
echo   1. Login Screen
echo   2. Trainer Dashboard - Overview
echo   3. Trainer Dashboard - Clients (with total sessions)
echo   4. Client Home Screen
echo   5. Booking Screen with Calendar
echo   6. Packages Screen
echo.
echo Press any key to close this window...
pause >nul
