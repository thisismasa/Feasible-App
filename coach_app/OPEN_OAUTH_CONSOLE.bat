@echo off
color 0B
echo.
echo ========================================
echo   Google OAuth Configuration Helper
echo ========================================
echo.
echo Your Cloudflare URL:
echo https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo This URL has been copied to your clipboard!
echo.

REM Copy Cloudflare URL to clipboard
echo https://tones-dancing-patches-searching.trycloudflare.com | clip

echo ========================================
echo.
echo Opening Google Cloud Console pages...
echo.
echo [1/2] Opening OAuth Consent Screen...
timeout /t 2 /nobreak >nul
start https://console.cloud.google.com/apis/credentials/consent

echo [2/2] Opening OAuth Client Settings...
timeout /t 2 /nobreak >nul
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

echo.
echo ========================================
echo   What to Do Now:
echo ========================================
echo.
echo OPTION 1: Enable Multiple Users (RECOMMENDED)
echo ----------------------------------------
echo In the "OAuth Consent Screen" page:
echo   1. Click "PUBLISH APP" button at top
echo   2. Click "CONFIRM"
echo   3. Done! Any Google user can sign in
echo.
echo OPTION 2: Add Current Cloudflare URL
echo ----------------------------------------
echo In the "OAuth Client" page:
echo   1. Scroll to "Authorized JavaScript origins"
echo   2. Click "+ ADD URI"
echo   3. Paste (Ctrl+V): https://tones-dancing-patches-searching.trycloudflare.com
echo   4. Scroll to "Authorized redirect URIs"
echo   5. Click "+ ADD URI"
echo   6. Paste (Ctrl+V): https://tones-dancing-patches-searching.trycloudflare.com
echo   7. Click "SAVE" at bottom
echo   8. Wait 5 minutes for changes to take effect
echo.
echo DO BOTH for best results!
echo.
echo ========================================
echo.

pause
