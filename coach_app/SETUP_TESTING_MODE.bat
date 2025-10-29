@echo off
color 0E
echo.
echo ========================================
echo   Setup Testing Mode (No Verification!)
echo ========================================
echo.
echo IMPORTANT: Do NOT publish to Production!
echo.
echo Testing Mode allows up to 100 users WITHOUT verification.
echo This is perfect for development and beta testing.
echo.
echo ========================================
echo   What You Need to Do:
echo ========================================
echo.
echo 1. KEEP app in Testing mode (do NOT publish)
echo 2. ADD test users (up to 100 Gmail addresses)
echo 3. ADD Cloudflare URL to authorized origins
echo.
echo ========================================
echo.

echo Copying Cloudflare URL to clipboard...
echo https://tones-dancing-patches-searching.trycloudflare.com | clip
echo Done!
echo.

echo Opening OAuth Consent Screen...
timeout /t 2 /nobreak >nul
start https://console.cloud.google.com/apis/credentials/consent

echo.
echo Opening OAuth Client Settings...
timeout /t 2 /nobreak >nul
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

echo.
echo ========================================
echo   Page 1: OAuth Consent Screen
echo ========================================
echo.
echo 1. Verify "Publishing status" shows "Testing"
echo    - If it says "In production", click "BACK TO TESTING"
echo.
echo 2. Scroll to "Test users" section
echo.
echo 3. Click "+ ADD USERS" button
echo.
echo 4. Enter Gmail addresses (one per line):
echo    masathomard@gmail.com
echo    friend1@gmail.com
echo    colleague@gmail.com
echo    [add up to 100 users]
echo.
echo 5. Click "SAVE"
echo.
echo ========================================
echo   Page 2: OAuth Client
echo ========================================
echo.
echo Cloudflare URL (already in clipboard):
echo https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo Add to "Authorized JavaScript origins":
echo   1. Click "+ ADD URI"
echo   2. Paste (Ctrl+V)
echo.
echo Add to "Authorized redirect URIs":
echo   1. Click "+ ADD URI"
echo   2. Paste (Ctrl+V)
echo.
echo 3. Click "SAVE" at bottom
echo.
echo ========================================
echo   Important Notes:
echo ========================================
echo.
echo - Testing mode = NO verification needed
echo - Can have up to 100 test users
echo - Users will see "unverified app" warning
echo - This is NORMAL and expected
echo - Users click "Continue" then "Allow"
echo - Full Calendar API access works
echo - Perfect for development/beta testing
echo.
echo ========================================
echo   After Setup:
echo ========================================
echo.
echo 1. Wait 5 minutes for changes to take effect
echo 2. Share this URL with test users:
echo    https://tones-dancing-patches-searching.trycloudflare.com
echo 3. Test users must be on the test users list
echo 4. They'll see "unverified app" warning (normal!)
echo 5. Click "Continue" -^> "Allow"
echo 6. Success!
echo.
echo ========================================
echo.

pause
