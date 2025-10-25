@echo off
title Running Coach App
color 0A

echo ============================================
echo    Starting Coach App...
echo ============================================
echo.

cd /d "%~dp0"

echo [1/3] Checking Flutter...
C:\src\flutter\bin\flutter.bat --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found at C:\src\flutter
    echo Please check your Flutter installation.
    pause
    exit /b 1
)

echo.
echo [2/3] Getting dependencies...
C:\src\flutter\bin\flutter.bat pub get

echo.
echo [3/3] Starting app on Chrome...
echo.
echo ============================================
echo  TIP: Once running, press 'r' to hot reload
echo       Press 'q' to quit
echo ============================================
echo.

C:\src\flutter\bin\flutter.bat run -d chrome

pause

