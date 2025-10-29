@echo off
title Setup Permanent Cloudflare Tunnel
color 0A

echo ========================================
echo   CLOUDFLARE PERMANENT TUNNEL SETUP
echo ========================================
echo.
echo This will create a PERMANENT tunnel URL that never changes!
echo.
echo STEPS:
echo   1. Login to Cloudflare (browser will open)
echo   2. Create a named tunnel called "feasible-app"
echo   3. Get your permanent URL
echo.

pause

echo.
echo [1/3] Opening Cloudflare login...
echo.

cloudflared tunnel login

echo.
echo ========================================
echo   DID THE LOGIN SUCCEED?
echo ========================================
echo.
echo If you see "You have successfully logged in" above, press any key to continue.
echo If login failed, close this window and try again.
echo.

pause

echo.
echo [2/3] Creating named tunnel "feasible-app"...
echo.

cloudflared tunnel create feasible-app

echo.
echo ========================================
echo   TUNNEL CREATED!
echo ========================================
echo.
echo Copy the tunnel ID shown above (long string of letters and numbers)
echo You'll need it in the next step.
echo.

pause

echo.
echo [3/3] Creating config file...
echo.
echo Please enter your TUNNEL ID (from above):
set /p TUNNEL_ID=

echo tunnel: %TUNNEL_ID% > %USERPROFILE%\.cloudflared\config.yml
echo credentials-file: %USERPROFILE%\.cloudflared\%TUNNEL_ID%.json >> %USERPROFILE%\.cloudflared\config.yml
echo. >> %USERPROFILE%\.cloudflared\config.yml
echo ingress: >> %USERPROFILE%\.cloudflared\config.yml
echo   - hostname: feasible-app.trycloudflare.com >> %USERPROFILE%\.cloudflared\config.yml
echo     service: http://localhost:8080 >> %USERPROFILE%\.cloudflared\config.yml
echo   - service: http_status:404 >> %USERPROFILE%\.cloudflared\config.yml

echo.
echo ✅ Config file created!
echo.

echo.
echo [4/4] Starting permanent tunnel...
echo.

cloudflared tunnel route dns feasible-app feasible-app.trycloudflare.com

echo.
echo ========================================
echo   ✅ SETUP COMPLETE!
echo ========================================
echo.
echo Your permanent URL is:
echo   https://feasible-app.trycloudflare.com
echo.
echo To start the tunnel, run:
echo   START_PERMANENT_TUNNEL.bat
echo.

pause
