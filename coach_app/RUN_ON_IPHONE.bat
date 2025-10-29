@echo off
color 0A
echo.
echo ========================================
echo      iPhone Deployment Options
echo ========================================
echo.
echo Choose deployment method:
echo.
echo [1] Native iOS App (Requires iPhone via USB)
echo [2] Web App via Cloudflare Tunnel (Recommended!)
echo [3] View Setup Guide
echo [Q] Quit
echo.
echo ========================================
echo.

choice /C 123Q /N /M "Enter your choice (1-3, Q): "

if errorlevel 4 goto :EOF
if errorlevel 3 goto GUIDE
if errorlevel 2 goto CLOUDFLARE
if errorlevel 1 goto NATIVE

:NATIVE
echo.
echo Starting Native iOS deployment...
call RUN_ON_IPHONE_NATIVE.bat
goto :EOF

:CLOUDFLARE
echo.
echo Starting Cloudflare Tunnel deployment...
powershell -ExecutionPolicy Bypass -File "RUN_CLOUDFLARE_TUNNEL.ps1"
goto :EOF

:GUIDE
echo.
echo Opening setup guide...
start IPHONE_DEPLOYMENT_GUIDE.md
timeout /t 2 /nobreak >nul
goto :EOF
