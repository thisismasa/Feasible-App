@echo off
cls
color 0B
echo.
echo ========================================
echo   Google Auth - Final Test
echo ========================================
echo.
echo Email added: masathomardforwork@gmail.com
echo App URL: https://notes-injuries-comparing-programming.trycloudflare.com
echo.
echo ========================================
echo   Next Steps:
echo ========================================
echo.
echo 1. Verify OAuth Client has the new URL
echo 2. Click SAVE if you just added it
echo 3. Wait 5 minutes
echo 4. Run this script again to test
echo.
echo ========================================
echo.

choice /C CT /N /M "Choose: [C]heck OAuth Client now, or [T]est sign-in (after 5 min wait): "

if errorlevel 2 goto TEST
if errorlevel 1 goto CHECK

:CHECK
echo.
echo Opening OAuth Client...
echo.
echo Verify these URLs are in BOTH sections:
echo   - Authorized JavaScript origins
echo   - Authorized redirect URIs
echo.
echo URL to add (in clipboard):
echo https://notes-injuries-comparing-programming.trycloudflare.com
echo.
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
echo.
echo After adding, click SAVE, then wait 5 minutes!
echo.
pause
exit

:TEST
echo.
echo ========================================
echo   Testing Google Sign-In
echo ========================================
echo.
echo Opening incognito Chrome...
timeout /t 2 /nobreak >nul

start chrome --new-window --incognito "https://notes-injuries-comparing-programming.trycloudflare.com"

echo.
echo In the incognito window:
echo   1. Click "Sign in with Google"
echo   2. Select: masathomardforwork@gmail.com
echo   3. If you see "unverified app" -^> Click "Continue"
echo   4. Click "Allow" for permissions
echo   5. Should redirect to dashboard!
echo.
echo ========================================
echo.

choice /C YN /N /M "Did sign-in work? [Y]es or [N]o: "

if errorlevel 2 goto FAILED
if errorlevel 1 goto SUCCESS

:SUCCESS
echo.
echo ========================================
echo   SUCCESS!
echo ========================================
echo.
echo Google Auth is now working!
echo.
echo You can now:
echo   - Access the app via Cloudflare URL
echo   - Sign in with: masathomardforwork@gmail.com
echo   - Use all features including Calendar sync
echo.
echo Your app is ready for testing!
echo.
echo ========================================
echo.
pause
exit

:FAILED
echo.
echo ========================================
echo   Troubleshooting
echo ========================================
echo.
echo Let's check what went wrong...
echo.

choice /C 123 /N /M "What error did you see? [1]Access blocked  [2]redirect_uri error  [3]Other: "

if errorlevel 3 goto OTHER
if errorlevel 2 goto REDIRECT
if errorlevel 1 goto BLOCKED

:BLOCKED
echo.
echo ERROR: Access blocked
echo.
echo This means your email is not in test users.
echo.
echo Let's verify:
start https://console.cloud.google.com/apis/credentials/consent
echo.
echo 1. Scroll to "Test users"
echo 2. Check if masathomardforwork@gmail.com is there
echo 3. If not, click "+ ADD USERS" and add it
echo 4. Click "SAVE"
echo 5. Wait 5 minutes
echo 6. Run this script again to test
echo.
pause
exit

:REDIRECT
echo.
echo ERROR: redirect_uri_mismatch
echo.
echo This means the Cloudflare URL is not in OAuth client.
echo.
echo Let's fix it:
echo https://notes-injuries-comparing-programming.trycloudflare.com | clip
echo.
echo URL copied to clipboard!
echo.
start https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com
echo.
echo 1. Add to "Authorized JavaScript origins" (Ctrl+V)
echo 2. Add to "Authorized redirect URIs" (Ctrl+V)
echo 3. Click SAVE
echo 4. Wait 5 minutes
echo 5. Run this script again to test
echo.
pause
exit

:OTHER
echo.
echo For other errors:
echo.
echo 1. Press F12 in Chrome
echo 2. Click "Console" tab
echo 3. Try sign-in again
echo 4. Look for error messages (red text)
echo 5. Note the error message
echo.
echo Common issues:
echo   - "popup_closed_by_user" -^> Don't close the popup
echo   - "cookies_disabled" -^> Enable cookies
echo   - "idpiframe_init_failed" -^> Clear cache or use incognito
echo.
pause
exit
