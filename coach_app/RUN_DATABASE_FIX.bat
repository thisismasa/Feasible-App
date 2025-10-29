@echo off
title Database Fix - Automatic Execution
color 0E

echo ========================================
echo   DATABASE DIAGNOSIS AND FIX
echo ========================================
echo.

set PGPASSWORD=Masathomard12
set DB_HOST=aws-0-ap-southeast-1.pooler.supabase.com
set DB_PORT=6543
set DB_NAME=postgres
set DB_USER=postgres.dkdnpceoanwbeulhkvdh

echo [1/3] Connecting to Supabase database...
echo   Host: %DB_HOST%
echo   Port: %DB_PORT%
echo   Database: %DB_NAME%
echo.

echo [2/3] Running comprehensive database fix...
echo   File: DIAGNOSE_AND_FIX_ALL.sql
echo.

psql "postgresql://%DB_USER%:%PGPASSWORD%@%DB_HOST%:%DB_PORT%/%DB_NAME%?sslmode=require" -f DIAGNOSE_AND_FIX_ALL.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   ✅ DATABASE FIX SUCCESSFUL!
    echo ========================================
    echo.
    echo All client packages should now work correctly!
    echo.
    echo Next steps:
    echo  1. Refresh your app in the browser
    echo  2. Go to "Select Client for Booking"
    echo  3. Clients with active packages should now appear
    echo.
) else (
    echo.
    echo ========================================
    echo   ❌ ERROR OCCURRED
    echo ========================================
    echo.
    echo Error code: %errorlevel%
    echo.
    echo Trying alternative connection...
    echo.

    REM Try with port 5432
    set DB_PORT=5432
    psql "postgresql://%DB_USER%:%PGPASSWORD%@%DB_HOST%:%DB_PORT%/%DB_NAME%?sslmode=require" -f DIAGNOSE_AND_FIX_ALL.sql

    if %errorlevel% equ 0 (
        echo.
        echo ✅ Connected successfully with port 5432!
        echo.
    ) else (
        echo.
        echo ❌ Connection failed on both ports (6543 and 5432)
        echo.
        echo Please check:
        echo  - Supabase project is running
        echo  - Database password is correct
        echo  - Network connection is stable
        echo.
    )
)

echo.
pause
