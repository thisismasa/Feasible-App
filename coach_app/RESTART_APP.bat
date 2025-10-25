@echo off
cls
title Restarting Coach App

echo ============================================
echo    Restarting Coach App with Device Preview
echo ============================================
echo.

cd /d "%~dp0"

REM Kill any Flutter processes
echo Stopping any running Flutter instances...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [1/4] Cleaning build cache...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
C:\src\flutter\bin\flutter.bat clean
echo Done!

echo.
echo [2/4] Getting fresh dependencies...
C:\src\flutter\bin\flutter.bat pub get
echo Done!

echo.
echo [3/4] Starting app...
echo.
echo ============================================
echo  Device Preview will show:
echo  - iPhone frames (left side)
echo  - Device selector (right side)
echo  - Your app in the middle!
echo ============================================
echo.
echo Please wait 2-3 minutes for compilation...
echo Chrome will open automatically!
echo.

C:\src\flutter\bin\flutter.bat run -d chrome

pause


