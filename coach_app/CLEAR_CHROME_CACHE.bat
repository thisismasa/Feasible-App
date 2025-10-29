@echo off
echo Clearing Chrome cache and opening app in incognito mode...
echo.

REM Open Chrome in incognito mode with your app
start chrome --incognito http://localhost:8081

echo.
echo Chrome opened in incognito mode.
echo This bypasses cached OAuth tokens.
echo.
echo Try signing in with Google again!
pause
