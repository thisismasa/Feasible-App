@echo off
title Configuration Verification
color 0B

echo ========================================
echo   Configuration Verification
echo ========================================
echo.

set CURRENT_URL=https://notes-injuries-comparing-programming.trycloudflare.com

echo [1/5] Verifying Cloudflare Tunnel...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" %CURRENT_URL%
if %errorlevel% equ 0 (
    echo   Status: ✓ Tunnel is accessible
) else (
    echo   Status: ✗ Tunnel not responding
)
echo.

echo [2/5] Testing Flutter App Response...
powershell -Command "try { $response = Invoke-WebRequest -Uri '%CURRENT_URL%' -TimeoutSec 5 -UseBasicParsing; if ($response.Content -like '*flutter*') { Write-Host '  Flutter App: ✓ Loaded correctly' } else { Write-Host '  Flutter App: ⚠ Response received but may not be Flutter' } } catch { Write-Host '  Flutter App: ✗ Not accessible' }"
echo.

echo [3/5] Checking Google OAuth Configuration...
echo   Opening OAuth client to verify...
echo.
echo   Please verify in the browser window:
echo.
echo   ✓ Authorized JavaScript origins includes:
echo     https://notes-injuries-comparing-programming.trycloudflare.com
echo.
echo   ✓ Authorized redirect URIs includes:
echo     https://notes-injuries-comparing-programming.trycloudflare.com
echo.
echo   ✓ Save button shows "Saved" or timestamp of last save
echo.

timeout /t 2 >nul

echo [4/5] Checking Supabase Auth Configuration...
echo   Opening Supabase Auth to verify...
echo.
echo   Please verify in the browser window:
echo.
echo   ✓ Google Provider is ENABLED (green toggle)
echo.
echo   ✓ Site URL is:
echo     https://notes-injuries-comparing-programming.trycloudflare.com
echo.
echo   ✓ Redirect URLs includes:
echo     https://notes-injuries-comparing-programming.trycloudflare.com
echo.

echo [5/5] Configuration Summary...
echo.
echo   Cloudflare URL: %CURRENT_URL%
echo   Google Client ID: 576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
echo   Supabase URL: https://dkdnpceoanwbeulhkvdh.supabase.co
echo   Test User: masathomardforwork@gmail.com
echo.

echo ========================================
echo   Ready to Test!
echo ========================================
echo.
echo IMPORTANT: Wait 5 minutes after saving OAuth changes!
echo.
echo Google needs time to propagate the new URLs.
echo If you just saved the changes, please wait before testing.
echo.
echo ========================================
echo   Testing Instructions
echo ========================================
echo.
echo 1. Open Chrome on your DESKTOP (not mobile yet)
echo.
echo 2. Go to: %CURRENT_URL%
echo.
echo 3. Click the RED "Google" button (bottom section)
echo.
echo 4. A popup should open - DON'T CLOSE IT!
echo.
echo 5. Sign in with: masathomardforwork@gmail.com
echo.
echo 6. Click "Allow" for permissions
echo.
echo 7. Should redirect to dashboard
echo.
echo ========================================
echo   Opening Test Pages...
echo ========================================
echo.

start chrome --new-window "%CURRENT_URL%"

timeout /t 2 >nul

start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

timeout /t 2 >nul

start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/auth/providers

echo.
echo ========================================
echo   What to Check
echo ========================================
echo.
echo Browser Window 1: YOUR APP
echo   - Should load the login page
echo   - Click the Google button to test
echo.
echo Browser Window 2: GOOGLE OAUTH CLIENT
echo   - Verify current URL is in BOTH sections
echo   - Check "last modified" timestamp is recent
echo.
echo Browser Window 3: SUPABASE AUTH
echo   - Verify Google provider is enabled
echo   - Check redirect URLs include current URL
echo.
echo ========================================
echo   After Testing
echo ========================================
echo.
echo Report back:
echo.
echo IF IT WORKS:
echo   - "Sign-in successful!"
echo   - "Redirected to dashboard"
echo.
echo IF IT FAILS:
echo   - What error message you see
echo   - Screenshot of the error
echo   - Did you wait 5 minutes after saving?
echo.
echo Press any key to close...
pause >nul
