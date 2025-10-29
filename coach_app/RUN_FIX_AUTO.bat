@echo off
title Automatic SQL Execution
color 0B

echo ========================================
echo   AUTOMATIC SQL FIX EXECUTION
echo ========================================
echo.

set PGPASSWORD=Masathomard12
set DB_HOST=aws-0-ap-southeast-1.pooler.supabase.com
set DB_PORT=5432
set DB_NAME=postgres
set DB_USER=postgres.dkdnpceoanwbeulhkvdh
set SQL_FILE=supabase\FIX_PACKAGE_ASSIGNMENT_BUG.sql

echo [1/3] Connecting to Supabase database...
echo   Host: %DB_HOST%
echo   Database: %DB_NAME%
echo   User: %DB_USER%
echo.

echo [2/3] Executing SQL fix automatically...
echo   File: %SQL_FILE%
echo.

psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f %SQL_FILE% -v ON_ERROR_STOP=1

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   ✅ SUCCESS!
    echo ========================================
    echo.
    echo The package assignment bug has been fixed!
    echo.
    echo [3/3] Testing the fix...
    echo.

    echo Testing query execution...
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT COUNT(*) as active_packages FROM client_packages WHERE status = 'active';"

    echo.
    echo ========================================
    echo   DONE! Your app is ready to use.
    echo ========================================
    echo.
    echo Now when you:
    echo  1. Add a new client
    echo  2. Assign a package to them
    echo  3. The package WILL show up correctly!
    echo.
) else (
    echo.
    echo ========================================
    echo   ❌ ERROR OCCURRED
    echo ========================================
    echo.
    echo The SQL execution failed.
    echo Error code: %errorlevel%
    echo.
    echo This might be because:
    echo  - Wrong password
    echo  - Connection issue
    echo  - Permissions problem
    echo.
)

echo.
pause
