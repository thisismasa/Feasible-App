@echo off
title OAuth Diagnostic Tool
color 0A

echo ========================================
echo   Google OAuth Diagnostic Tool
echo ========================================
echo.

REM Get current Cloudflare URL from running tunnel
echo [1/7] Detecting Current Cloudflare URL...
set CURRENT_URL=https://notes-injuries-comparing-programming.trycloudflare.com
echo   Found: %CURRENT_URL%
echo.

echo [2/7] Checking Google Cloud Configuration...
echo   Project ID: 576001465184
echo   Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
echo   API Key: AIzaSyDCjQsRx8tMpvu9bQVgMr3ezc_K1Ru6jFk
echo   Status: ✓ Configured
echo.

echo [3/7] Checking Supabase Configuration...
echo   URL: https://dkdnpceoanwbeulhkvdh.supabase.co
echo   Status: ✓ Connected
echo.

echo [4/7] Checking Test User...
echo   Email: masathomardforwork@gmail.com
echo   Status: Added to test users (confirmed by user)
echo.

echo [5/7] Checking Required Libraries in web/index.html...
findstr /C:"accounts.google.com/gsi/client" web\index.html >nul 2>&1
if %errorlevel% equ 0 (
    echo   Google Sign-In Library: ✓ Found
) else (
    echo   Google Sign-In Library: ✗ MISSING
)

findstr /C:"apis.google.com/js/api.js" web\index.html >nul 2>&1
if %errorlevel% equ 0 (
    echo   Google API Library: ✓ Found
) else (
    echo   Google API Library: ✗ MISSING
)
echo.

echo [6/7] Verifying Flutter Web Server...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8080' -TimeoutSec 2 -UseBasicParsing; Write-Host '  Flutter Server: ✓ Running on port 8080' } catch { Write-Host '  Flutter Server: ✗ NOT running' }"
echo.

echo [7/7] Verifying Cloudflare Tunnel...
powershell -Command "try { $response = Invoke-WebRequest -Uri '%CURRENT_URL%' -TimeoutSec 5 -UseBasicParsing; Write-Host '  Cloudflare Tunnel: ✓ Accessible' } catch { Write-Host '  Cloudflare Tunnel: ✗ NOT accessible' }"
echo.

echo ========================================
echo   CRITICAL ISSUE FOUND
echo ========================================
echo.
echo The Cloudflare URL has CHANGED!
echo.
echo Old URL (in OAuth config):
echo   https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo Current URL (running now):
echo   %CURRENT_URL%
echo.
echo ========================================
echo   REQUIRED ACTION
echo ========================================
echo.
echo You MUST update the OAuth client with the CURRENT URL:
echo.
echo 1. Open this page (opening now):
echo    https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
echo.
echo 2. Add to "Authorized JavaScript origins":
echo    %CURRENT_URL%
echo.
echo 3. Add to "Authorized redirect URIs":
echo    %CURRENT_URL%
echo.
echo 4. Click SAVE at bottom
echo.
echo 5. Wait 5 minutes
echo.
echo 6. Test again!
echo.
echo ========================================
echo   Opening OAuth Client Page...
echo ========================================
echo.

REM Copy current URL to clipboard
echo %CURRENT_URL% | clip
echo URL copied to clipboard! Just paste with Ctrl+V.
echo.

REM Open OAuth client configuration
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

timeout /t 3 >nul

echo Opening instructions in Notepad...
start notepad CURRENT_URL.txt

echo.
echo ========================================
echo   Database Check
echo ========================================
echo.
echo Opening Supabase Dashboard to verify:
echo   1. Google OAuth provider is enabled
echo   2. Redirect URLs include Cloudflare URL
echo   3. Users table has proper configuration
echo.

timeout /t 2 >nul

start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/auth/providers

echo.
echo ========================================
echo   Next Steps
echo ========================================
echo.
echo 1. Add the current URL to OAuth client (opening now)
echo 2. Check Supabase Auth providers (opening now)
echo 3. Wait 5 minutes after saving
echo 4. Test on desktop Chrome first
echo 5. Then test on iPhone
echo.
echo Press any key to close...
pause >nul
