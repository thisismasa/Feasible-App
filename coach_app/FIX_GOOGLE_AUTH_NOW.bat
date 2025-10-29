@echo off
color 0C
echo.
echo ========================================
echo   EMERGENCY: Fix Google Auth Block
echo ========================================
echo.
echo Your Cloudflare URL is running at:
echo https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo Google is blocking because:
echo   1. Your email is NOT in test users list
echo   2. Cloudflare URL is NOT in authorized origins
echo.
echo Let's fix this NOW!
echo.
echo ========================================
echo.

REM Copy Cloudflare URL to clipboard
echo https://tones-dancing-patches-searching.trycloudflare.com | clip
echo Cloudflare URL copied to clipboard!
echo.

echo Opening Google Cloud Console pages...
timeout /t 2 /nobreak >nul

REM Open OAuth Consent Screen (for adding test users)
start https://console.cloud.google.com/apis/credentials/consent

timeout /t 2 /nobreak >nul

REM Open OAuth Client Settings (for adding URLs)
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

echo.
echo ========================================
echo   PAGE 1: OAuth Consent Screen
echo ========================================
echo.
echo DO THIS FIRST:
echo.
echo 1. Find "Publishing status" at the top
echo    - Should say "Testing"
echo    - If it says "In production" -^> Click "BACK TO TESTING"
echo.
echo 2. Scroll down to "Test users" section
echo.
echo 3. Click "+ ADD USERS" button
echo.
echo 4. Enter YOUR Gmail address
echo    Example: masathomard@gmail.com
echo.
echo 5. Click "SAVE"
echo.
echo 6. VERIFY your email appears in the list
echo.
echo Press any key when done...
pause >nul

echo.
echo ========================================
echo   PAGE 2: OAuth Client Settings
echo ========================================
echo.
echo NOW DO THIS:
echo.
echo The Cloudflare URL is in your clipboard:
echo https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo STEP 1: Add to "Authorized JavaScript origins"
echo   1. Scroll to that section
echo   2. Click "+ ADD URI"
echo   3. Paste (Ctrl+V)
echo   4. You should see the Cloudflare URL appear
echo.
echo STEP 2: Add to "Authorized redirect URIs"
echo   1. Scroll to that section
echo   2. Click "+ ADD URI"
echo   3. Paste (Ctrl+V) again
echo   4. You should see the Cloudflare URL appear
echo.
echo STEP 3: SAVE!
echo   1. Scroll to bottom
echo   2. Click "SAVE" button
echo   3. Wait for "Saved" confirmation
echo.
echo Press any key when done...
pause >nul

echo.
echo ========================================
echo   WAIT 5 MINUTES
echo ========================================
echo.
echo Google needs time to propagate your changes.
echo.
echo This will take approximately 5 minutes.
echo.
echo Starting countdown timer...
echo.

REM 5 minute countdown
for /L %%i in (5,-1,1) do (
    echo %%i minutes remaining...
    timeout /t 60 /nobreak >nul
)

echo.
echo Time's up! Changes should be active now.
echo.

echo ========================================
echo   TEST YOUR ACCESS
echo ========================================
echo.
echo Opening your app in browser...
timeout /t 2 /nobreak >nul

start https://tones-dancing-patches-searching.trycloudflare.com

echo.
echo In the browser:
echo   1. Click "Sign in with Google"
echo   2. Select your Gmail account
echo   3. You may see "unverified app" warning
echo      -^> Click "Advanced" or "Continue"
echo      -^> Click "Go to app"
echo   4. Click "Allow" to grant permissions
echo   5. You should be logged in!
echo.
echo ========================================
echo   If Still Blocked:
echo ========================================
echo.
echo Try these:
echo.
echo 1. Use INCOGNITO MODE:
echo    - Press Ctrl+Shift+N in Chrome
echo    - Go to the Cloudflare URL
echo    - Try signing in again
echo.
echo 2. Clear browser cache:
echo    - Press Ctrl+Shift+Delete
echo    - Clear last hour
echo    - Try again
echo.
echo 3. Revoke app access:
echo    - Go to: https://myaccount.google.com/permissions
echo    - Remove "coach_app" if it exists
echo    - Try signing in again
echo.
echo 4. Check exact error:
echo    - Press F12 in browser
echo    - Click "Console" tab
echo    - Look for error messages
echo    - Share the error with me
echo.
echo ========================================
echo.

pause
