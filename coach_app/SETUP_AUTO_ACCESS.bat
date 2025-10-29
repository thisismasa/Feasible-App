@echo off
color 0A
echo.
echo ========================================
echo   Auto User Access Setup
echo ========================================
echo.
echo This will set up automatic user approval so your friends
echo can access WITHOUT you manually adding their emails!
echo.
echo ========================================
echo.

echo Step 1: Install Database Schema
echo --------------------------------
echo.
echo Opening Supabase SQL Editor...
timeout /t 2 /nobreak >nul

REM Copy SQL to clipboard
type "supabase\AUTO_USER_ACCESS_SYSTEM.sql" | clip

start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new

echo.
echo The SQL has been copied to your clipboard!
echo.
echo In the Supabase SQL Editor:
echo   1. Paste (Ctrl+V) the SQL code
echo   2. Click "Run" button
echo   3. Wait for "Success" message
echo.
echo Press any key when done...
pause >nul

echo.
echo ========================================
echo Step 2: Generate Invite Codes
echo ========================================
echo.

REM Copy invite generation SQL to clipboard
type "GENERATE_INVITE_CODES.sql" | clip

start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new

echo.
echo The invite code generator has been copied to clipboard!
echo.
echo In the new SQL Editor tab:
echo   1. Paste (Ctrl+V) the SQL code
echo   2. Click "Run" button
echo   3. You'll see 5 invite links generated!
echo.
echo Press any key when done...
pause >nul

echo.
echo ========================================
echo Step 3: Share Links with Friends
echo ========================================
echo.
echo Copy the 5 invite links from the SQL results.
echo.
echo Each link looks like:
echo https://tones-dancing-patches-searching.trycloudflare.com/?invite=ABC12345
echo.
echo Send each friend their unique link!
echo.
echo When they click the link and sign in with Google:
echo   - Automatically approved (no waiting!)
echo   - Full access immediately
echo   - No manual email entry needed from you!
echo.
echo ========================================
echo   Alternative: Auto-Approve All Gmail
echo ========================================
echo.
echo Want to auto-approve ANYONE with @gmail.com?
echo.
choice /C YN /N /M "Enable auto-approval for all Gmail users? (Y/N): "

if errorlevel 2 goto SKIP_AUTO_GMAIL
if errorlevel 1 goto ENABLE_AUTO_GMAIL

:ENABLE_AUTO_GMAIL
echo.
echo Enabling auto-approval for @gmail.com...
echo.

REM Create SQL for auto-approval
(
echo INSERT INTO auto_approval_rules ^(rule_type, rule_value, notes^)
echo VALUES ^('domain', '@gmail.com', 'Auto-approve all Gmail users'^);
echo.
echo SELECT 'Auto-approval enabled for all Gmail users!' as status;
) > temp_auto_gmail.sql

type temp_auto_gmail.sql | clip

start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new

echo.
echo SQL copied to clipboard!
echo   1. Paste in SQL Editor
echo   2. Click "Run"
echo   3. Done!
echo.
echo Now ANYONE with @gmail.com can sign in and get auto-approved!
echo.
del temp_auto_gmail.sql
pause
goto DONE

:SKIP_AUTO_GMAIL
echo.
echo Skipped. Using invite codes only.
echo.

:DONE
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo What you now have:
echo   - Database tables for user management
echo   - 5 invite codes for your friends
echo   - Auto-approval system running
echo.
echo Your friends can now access via:
echo   1. Invite links (you send them)
echo   2. Auto-approval (if you enabled Gmail auto-approve)
echo.
echo NO manual email entry needed!
echo.
echo ========================================
echo   Next Steps:
echo ========================================
echo.
echo 1. Copy the 5 invite links from Supabase SQL results
echo 2. Send each friend their link via WhatsApp/Email/SMS
echo 3. When they click and sign in, they're auto-approved!
echo 4. Monitor access via Supabase dashboard
echo.
echo To generate more invite codes later:
echo   - Run GENERATE_INVITE_CODES.sql in Supabase
echo.
echo ========================================
echo.

pause
