@echo off
cd /d "%~dp0"
echo Starting Flutter App...
echo.
echo This will open in Chrome with iPhone preview!
echo Please wait 2-3 minutes...
echo.
C:\src\flutter\bin\flutter.bat run -d chrome
pause


