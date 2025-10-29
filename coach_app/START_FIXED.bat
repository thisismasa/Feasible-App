@echo off
title Flutter Web Server + Cloudflare Tunnel
color 0B

echo ========================================
echo   Starting Flutter App + Cloudflare
echo ========================================
echo.

echo [1/4] Checking build directory...
if not exist "build\web\index.html" (
    echo   ERROR: build\web\index.html not found!
    echo   The Flutter web app needs to be built first.
    echo.
    pause
    exit /b 1
)
echo   OK: Build directory exists
echo.

echo [2/4] Stopping any existing servers on port 8080...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8080" ^| find "LISTENING"') do taskkill /F /PID %%a 2>nul
timeout /t 2 >nul
echo   OK: Port 8080 is clear
echo.

echo [3/4] Starting Python HTTP server...
cd build\web
start /B python -m http.server 8080
cd ..\..
timeout /t 3 >nul

echo   Testing server...
curl -s -o nul -w "HTTP %%{http_code}\n" http://localhost:8080
if %errorlevel% equ 0 (
    echo   OK: Server is running
) else (
    echo   WARNING: Server may not be ready yet
)
echo.

echo [4/4] Starting Cloudflare Tunnel...
echo.
echo ========================================
echo   Your app URL will appear below:
echo ========================================
echo.

cloudflared tunnel --url http://localhost:8080

echo.
echo Tunnel stopped. Cleaning up...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8080" ^| find "LISTENING"') do taskkill /F /PID %%a 2>nul
