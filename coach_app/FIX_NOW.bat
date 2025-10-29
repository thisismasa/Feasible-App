@echo off
cls
color 0A
echo.
echo =============================================
echo   GOOGLE AUTH FIX - One-Click Solution
echo =============================================
echo.
echo Your Cloudflare Tunnel:
echo https://tones-dancing-patches-searching.trycloudflare.com
echo.
echo I will open 2 browser tabs. Do these steps:
echo.
echo TAB 1 - Add Your Email:
echo   1. Scroll to "Test users"
echo   2. Click "+ ADD USERS"
echo   3. Type your Gmail address
echo   4. Click SAVE
echo.
echo TAB 2 - Add Cloudflare URL:
echo   1. Find "Authorized JavaScript origins"
echo   2. Click "+ ADD URI"
echo   3. Paste: https://tones-dancing-patches-searching.trycloudflare.com
echo   4. Find "Authorized redirect URIs"
echo   5. Click "+ ADD URI"
echo   6. Paste again
echo   7. Click SAVE at bottom
echo.
pause

echo Copying URL to clipboard...
echo https://tones-dancing-patches-searching.trycloudflare.com | clip

echo Opening browsers...
start https://console.cloud.google.com/apis/credentials/consent
timeout /t 2 /nobreak >nul
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com

echo.
echo =============================================
echo Complete the steps above, then press any key
echo =============================================
pause >nul

echo.
echo Waiting 5 minutes for Google to update...
echo.
for /L %%i in (5,-1,1) do (
    echo %%i minutes remaining...
    timeout /t 60 /nobreak >nul
)

echo.
echo Opening your app...
start https://tones-dancing-patches-searching.trycloudflare.com

echo.
echo =============================================
echo Now click "Sign in with Google" and test!
echo =============================================
echo.
pause
