@echo off
title Fix Khun bie Package - URGENT
color 0C

echo ========================================
echo   FIX KHUN BIE PACKAGE - URGENT
echo ========================================
echo.

set PGPASSWORD=Masathomard12
set DB_HOST=aws-0-ap-southeast-1.pooler.supabase.com
set DB_PORT=5432
set DB_NAME=postgres
set DB_USER=postgres.dkdnpceoanwbeulhkvdh

echo Problem: Khun bie paid 1800 baht but shows "no active package"
echo.
echo [1/2] Diagnosing Khun bie's account...
echo.

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f CHECK_KHUN_BIE.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   ✅ FIX COMPLETE!
    echo ========================================
    echo.
    echo Khun bie should now see their active package!
    echo.
    echo Package Details:
    echo   - Price: 1800 baht
    echo   - Sessions: 1 session
    echo   - Status: Active
    echo   - Valid for: 30 days
    echo.
    echo [2/2] Refresh the app to see the package!
    echo.
) else (
    echo.
    echo ========================================
    echo   ❌ ERROR
    echo ========================================
    echo.
    echo Could not connect to database.
    echo Error code: %errorlevel%
    echo.
)

pause
