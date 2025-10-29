@echo off
echo ====================================
echo Testing Cloudflare Tunnel Setup
echo ====================================
echo.

echo Checking cloudflared installation...
cloudflared --version
if %errorlevel% neq 0 (
    echo ERROR: cloudflared not found!
    pause
    exit /b 1
)

echo.
echo SUCCESS: Cloudflare Tunnel is ready!
echo.
echo ====================================
echo Quick Test Instructions:
echo ====================================
echo.
echo To run your app on iPhone:
echo.
echo 1. Run: RUN_ON_IPHONE.bat
echo 2. Choose option [2] for Cloudflare Tunnel
echo 3. Copy the URL (https://xxx.trycloudflare.com)
echo 4. Open it on your iPhone's Safari browser
echo.
echo ====================================
echo.

pause
