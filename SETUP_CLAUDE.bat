@echo off
color 0B
title Setup Claude Opus 4.1 in Terminal

:MENU
cls
echo ============================================
echo    Claude Opus 4.1 Terminal Setup
echo ============================================
echo.
echo Choose an option:
echo.
echo 1. Check if Python is installed
echo 2. Install Anthropic library
echo 3. Set API key
echo 4. Test Claude (interactive chat)
echo 5. Test Claude (single question)
echo 6. Open setup guide
echo 7. Exit
echo.
echo ============================================
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto CHECK_PYTHON
if "%choice%"=="2" goto INSTALL_LIB
if "%choice%"=="3" goto SET_KEY
if "%choice%"=="4" goto RUN_CHAT
if "%choice%"=="5" goto RUN_CLI
if "%choice%"=="6" goto OPEN_GUIDE
if "%choice%"=="7" goto EXIT

echo Invalid choice!
timeout /t 2 >nul
goto MENU

:CHECK_PYTHON
cls
echo ============================================
echo    Checking Python Installation...
echo ============================================
echo.
python --version
if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo SUCCESS! Python is installed!
    echo ============================================
    echo.
    echo Next step: Install Anthropic library (option 2)
) else (
    echo.
    echo ============================================
    echo Python is NOT installed
    echo ============================================
    echo.
    echo Download from: https://www.python.org/downloads/
    echo IMPORTANT: Check "Add Python to PATH" during install
    echo.
)
echo.
pause
goto MENU

:INSTALL_LIB
cls
echo ============================================
echo    Installing Anthropic Library...
echo ============================================
echo.
echo This will install the Claude API client...
echo.
pip install anthropic
echo.
if %errorlevel% equ 0 (
    echo ============================================
    echo SUCCESS! Library installed!
    echo ============================================
    echo.
    echo Next step: Set your API key (option 3)
) else (
    echo ============================================
    echo Installation failed!
    echo ============================================
    echo.
    echo Try running PowerShell as Administrator
)
echo.
pause
goto MENU

:SET_KEY
cls
echo ============================================
echo    Set Your Anthropic API Key
echo ============================================
echo.
echo To use Claude, you need an API key from:
echo https://console.anthropic.com/
echo.
echo Enter your API key (starts with sk-ant-):
set /p apikey="API Key: "

if "%apikey%"=="" (
    echo No API key entered!
    timeout /t 2 >nul
    goto MENU
)

echo.
echo Setting API key...
setx ANTHROPIC_API_KEY "%apikey%"

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo SUCCESS! API key saved!
    echo ============================================
    echo.
    echo IMPORTANT: Close this window and open a NEW
    echo terminal for the API key to take effect.
    echo.
    echo Then run this script again and choose option 4
    echo to test Claude!
) else (
    echo.
    echo Failed to set API key!
)
echo.
pause
goto MENU

:RUN_CHAT
cls
echo ============================================
echo    Starting Claude Interactive Chat...
echo ============================================
echo.
echo Launching claude-chat.py...
echo.
python claude-chat.py
echo.
pause
goto MENU

:RUN_CLI
cls
echo ============================================
echo    Claude Single Question Mode
echo ============================================
echo.
set /p question="Ask Claude a question: "

if "%question%"=="" (
    echo No question entered!
    timeout /t 2 >nul
    goto MENU
)

echo.
python claude-cli.py "%question%"
echo.
pause
goto MENU

:OPEN_GUIDE
cls
echo ============================================
echo    Opening Setup Guide...
echo ============================================
echo.
start "" "CLAUDE_CLI_SETUP.md"
echo.
echo Guide opened!
pause
goto MENU

:EXIT
cls
echo.
echo ============================================
echo Thank you for using Claude CLI!
echo ============================================
echo.
echo Quick commands after setup:
echo   - python claude-chat.py (interactive)
echo   - python claude-cli.py "question" (single)
echo.
echo Get API key: https://console.anthropic.com/
echo.
timeout /t 3 >nul
exit
