@echo off
echo ============================================
echo AUTOMATIC SQL EXECUTOR WITH psql
echo ============================================
echo.

REM psql location
set "PSQL=C:\Users\masathomard\scoop\apps\postgresql\current\bin\psql.exe"

REM Check if db-config.txt exists
if not exist "db-config.txt" (
    echo ERROR: db-config.txt not found!
    echo.
    echo Creating db-config.txt template...
    echo DATABASE_URL=postgresql://postgres.dkdnpceoanwbeulhkvdh:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:5432/postgres > db-config.txt
    echo.
    echo Please edit db-config.txt and replace [YOUR-PASSWORD] with your actual password.
    echo Get it from: https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/settings/database
    echo.
    pause
    exit /b 1
)

REM Read database URL from config
for /f "tokens=1,* delims==" %%a in (db-config.txt) do (
    if "%%a"=="DATABASE_URL" set "DB_URL=%%b"
)

REM Check if SQL file was provided
set "SQL_FILE=%1"
if "%SQL_FILE%"=="" (
    set "SQL_FILE=VERIFY_PACKAGE_FIX.sql"
    echo No file specified, using default: VERIFY_PACKAGE_FIX.sql
    echo.
)

echo Executing: %SQL_FILE%
echo Connecting to Supabase...
echo.

REM Execute SQL using psql
"%PSQL%" "%DB_URL%" -f "%SQL_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo ✅ SQL EXECUTED SUCCESSFULLY!
    echo ============================================
) else (
    echo.
    echo ============================================
    echo ❌ SQL EXECUTION FAILED!
    echo ============================================
)

echo.
pause
