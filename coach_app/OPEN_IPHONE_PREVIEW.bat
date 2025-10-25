@echo off
title Coach App - iPhone Preview
color 0B

echo ============================================
echo    Coach App - iPhone Virtual Preview
echo ============================================
echo.
echo Cleaning and starting your app...
echo.

cd /d "%~dp0"

REM Kill any hanging processes
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul

echo [1/4] Deleting build cache...
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
echo OK

echo.
echo [2/4] Flutter clean...
C:\src\flutter\bin\flutter.bat clean

echo.
echo [3/4] Getting dependencies...
C:\src\flutter\bin\flutter.bat pub get

echo.
echo [4/4] Starting app with iPhone preview...
echo.
echo ============================================
echo  What you'll see:
echo ============================================
echo  - iPhone frame in Chrome
echo  - Device selector (top-left)
echo  - Rotate, dark mode, screenshot buttons
echo.
echo  Hot Reload: Press 'r' to update!
echo ============================================
echo.
echo Please wait 2-3 minutes for first build...
echo.

C:\src\flutter\bin\flutter.bat run -d chrome

pause



