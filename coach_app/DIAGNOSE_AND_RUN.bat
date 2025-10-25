@echo off
cls
title Coach App Diagnostics
color 0E

cd /d "%~dp0"

echo ============================================
echo    Coach App - Diagnostics and Run
echo ============================================
echo.

echo [CHECK 1] Flutter installation...
C:\src\flutter\bin\flutter.bat --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found!
    pause
    exit /b 1
)
echo.

echo [CHECK 2] pubspec.yaml exists...
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Current directory: %cd%
    pause
    exit /b 1
)
echo OK - pubspec.yaml found!
echo.

echo [CHECK 3] Chrome available...
C:\src\flutter\bin\flutter.bat devices | findstr /i "chrome"
echo.

echo [FIX 1] Cleaning build cache...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
C:\src\flutter\bin\flutter.bat clean
echo.

echo [FIX 2] Getting dependencies...
C:\src\flutter\bin\flutter.bat pub get
echo.

echo [RUN] Starting app on Chrome...
echo.
echo ============================================
echo  Watch this terminal for:
echo  - "Launching lib\main.dart on Chrome..."
echo  - "Application running on http://localhost:XXXXX"
echo ============================================
echo.
echo This will take 2-3 minutes on first run...
echo Chrome will open automatically when ready!
echo.

C:\src\flutter\bin\flutter.bat run -d chrome

pause


