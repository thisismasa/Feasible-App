@echo off
title Feasible App - Permanent Tunnel
color 0B

echo ========================================
echo   FEASIBLE APP - PERMANENT TUNNEL
echo ========================================
echo.
echo Starting tunnel with your permanent URL...
echo.
echo Your app will be accessible at:
echo   https://feasible-app.trycloudflare.com
echo.
echo Keep this window open while using the app!
echo.

cloudflared tunnel run feasible-app

pause
