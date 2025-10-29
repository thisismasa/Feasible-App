@echo off
echo ====================================
echo Running Flutter Web with Cloudflare Tunnel
echo ====================================
echo.

cd /d "%~dp0"

echo Step 1: Starting Flutter Web Server...
start cmd /k "flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0"

timeout /t 5 /nobreak >nul

echo.
echo Step 2: Starting Cloudflare Tunnel...
echo This will create a public URL for your iPhone to access
echo.

cloudflared tunnel --url http://localhost:8080

pause
