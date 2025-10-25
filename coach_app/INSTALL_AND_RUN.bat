@echo off
color 0A
title Coach App - Flutter Installation Helper

:MENU
cls
echo ============================================
echo    COACH APP - Flutter Installation
echo ============================================
echo.
echo Choose an option:
echo.
echo 1. Check if Flutter is installed
echo 2. Download Flutter (opens browser)
echo 3. Help me add Flutter to PATH
echo 4. Run the app (after Flutter installed)
echo 5. View UI Mockup (no installation needed)
echo 6. Open installation guide
echo 7. Exit
echo.
echo ============================================
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto CHECK_FLUTTER
if "%choice%"=="2" goto DOWNLOAD_FLUTTER
if "%choice%"=="3" goto SETUP_PATH
if "%choice%"=="4" goto RUN_APP
if "%choice%"=="5" goto VIEW_MOCKUP
if "%choice%"=="6" goto OPEN_GUIDE
if "%choice%"=="7" goto EXIT

echo Invalid choice!
timeout /t 2 >nul
goto MENU

:CHECK_FLUTTER
cls
echo ============================================
echo    Checking Flutter Installation...
echo ============================================
echo.
flutter --version
if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo SUCCESS! Flutter is installed!
    echo ============================================
    echo.
    echo You can now run your app!
    echo Press any key to return to menu...
) else (
    echo.
    echo ============================================
    echo Flutter is NOT installed
    echo ============================================
    echo.
    echo Please choose option 2 to download Flutter
    echo Press any key to return to menu...
)
pause >nul
goto MENU

:DOWNLOAD_FLUTTER
cls
echo ============================================
echo    Opening Flutter Download Page...
echo ============================================
echo.
echo Opening browser to download Flutter...
echo.
echo After download:
echo 1. Extract ZIP to C:\src\flutter
echo 2. Come back and choose option 3
echo.
start https://docs.flutter.dev/get-started/install/windows
echo.
echo Press any key when download is complete...
pause >nul
goto MENU

:SETUP_PATH
cls
echo ============================================
echo    Setting up Flutter PATH
echo ============================================
echo.
echo STEP 1: Did you extract Flutter to C:\src\flutter?
echo.
set /p extracted="Type 'yes' if extracted: "
if /i not "%extracted%"=="yes" (
    echo.
    echo Please extract Flutter first!
    echo Extract the downloaded ZIP to: C:\src\flutter
    timeout /t 3 >nul
    goto MENU
)
echo.
echo STEP 2: Opening System Properties...
echo.
echo In the window that opens:
echo 1. Click 'Environment Variables' button
echo 2. Under 'User variables', find 'Path'
echo 3. Click 'Edit'
echo 4. Click 'New'
echo 5. Type: C:\src\flutter\bin
echo 6. Click OK on all windows
echo.
echo Press any key to open System Properties...
pause >nul
rundll32 sysdm.cpl,EditEnvironmentVariables
echo.
echo After adding Flutter to PATH:
echo 1. CLOSE this window
echo 2. Open NEW Command Prompt
echo 3. Run this bat file again
echo 4. Choose option 1 to verify
echo.
pause
goto MENU

:RUN_APP
cls
echo ============================================
echo    Running Your Coach App
echo ============================================
echo.
echo Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Flutter not found!
    echo Please install Flutter first (option 1-3)
    echo.
    pause
    goto MENU
)
echo.
echo Flutter found! Starting app setup...
echo.
echo Step 1: Enabling web support...
flutter config --enable-web
echo.
echo Step 2: Getting dependencies...
flutter pub get
echo.
echo Step 3: Checking devices...
flutter devices
echo.
echo ============================================
echo Choose how to run:
echo ============================================
echo 1. Run on Chrome (fastest, no emulator needed)
echo 2. Run on Windows Desktop
echo 3. Check what devices are available
echo 4. Back to menu
echo.
set /p runchoice="Enter choice (1-4): "

if "%runchoice%"=="1" goto RUN_CHROME
if "%runchoice%"=="2" goto RUN_WINDOWS
if "%runchoice%"=="3" goto CHECK_DEVICES
if "%runchoice%"=="4" goto MENU

:RUN_CHROME
echo.
echo Starting app on Chrome...
echo.
echo TIP: After app starts, press 'r' for hot reload
echo      Press 'q' to quit
echo.
flutter run -d chrome
pause
goto MENU

:RUN_WINDOWS
echo.
echo Enabling Windows desktop...
flutter config --enable-windows-desktop
echo.
echo Starting app on Windows...
flutter run -d windows
pause
goto MENU

:CHECK_DEVICES
echo.
flutter devices
echo.
pause
goto RUN_APP

:VIEW_MOCKUP
cls
echo ============================================
echo    Opening UI Mockup...
echo ============================================
echo.
echo Opening mockup in your browser...
echo This shows what your app looks like!
echo.
start "" "%~dp0UI_MOCKUP.html"
echo.
echo Mockup opened! Press any key to return...
pause >nul
goto MENU

:OPEN_GUIDE
cls
echo ============================================
echo    Opening Installation Guide...
echo ============================================
echo.
start "" "%~dp0INSTALL_FLUTTER_NOW.md"
echo.
echo Guide opened! Press any key to return...
pause >nul
goto MENU

:EXIT
cls
echo.
echo ============================================
echo Thank you for using Coach App installer!
echo ============================================
echo.
echo Quick tips:
echo - View UI mockup: OPEN_UI_MOCKUP.bat
echo - Read guide: INSTALL_FLUTTER_NOW.md
echo - After Flutter installed: Run this again!
echo.
echo Good luck with your coaching app!
echo.
timeout /t 3 >nul
exit
