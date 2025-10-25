@echo off
echo =====================================================
echo Cleaning Up Old/Redundant SQL Files
echo =====================================================
echo.

cd /d "%~dp0supabase"

echo Deleting outdated SQL files...
echo.

if exist "assign_to_your_trainer.sql" (
    del "assign_to_your_trainer.sql"
    echo [DELETED] assign_to_your_trainer.sql
)

if exist "auto_create_user_on_signup.sql" (
    del "auto_create_user_on_signup.sql"
    echo [DELETED] auto_create_user_on_signup.sql
)

if exist "CHECK_DATABASE_FIRST.sql" (
    del "CHECK_DATABASE_FIRST.sql"
    echo [DELETED] CHECK_DATABASE_FIRST.sql
)

if exist "COPY_AND_RUN_THIS.sql" (
    del "COPY_AND_RUN_THIS.sql"
    echo [DELETED] COPY_AND_RUN_THIS.sql
)

if exist "create_trainer_user.sql" (
    del "create_trainer_user.sql"
    echo [DELETED] create_trainer_user.sql
)

if exist "fix_assign_clients.sql" (
    del "fix_assign_clients.sql"
    echo [DELETED] fix_assign_clients.sql
)

if exist "RUN_THIS_NOW.sql" (
    del "RUN_THIS_NOW.sql"
    echo [DELETED] RUN_THIS_NOW.sql
)

echo.
echo =====================================================
echo Cleanup Complete!
echo =====================================================
echo.
echo Files KEPT (still useful):
echo   - migrations/001_enterprise_client_schema.sql
echo   - migrations/002_complete_enterprise_schema_sync.sql
echo   - migrations/003_booking_integration_fix.sql
echo   - migrations/004_booking_integration_final.sql
echo   - migrations/005_add_trainer_clients_table.sql
echo   - COMPLETE_SETUP_FOR_ANY_USER.sql (USE THIS!)
echo.
echo Files DELETED (outdated):
echo   - assign_to_your_trainer.sql
echo   - auto_create_user_on_signup.sql
echo   - CHECK_DATABASE_FIRST.sql
echo   - COPY_AND_RUN_THIS.sql
echo   - create_trainer_user.sql
echo   - fix_assign_clients.sql
echo   - RUN_THIS_NOW.sql
echo.
pause
