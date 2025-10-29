@echo off
title Install Auto-Package Trigger - ONE TIME SETUP
color 0E

echo ========================================
echo   INSTALL AUTO-PACKAGE TRIGGER
echo ========================================
echo.
echo This is a ONE-TIME setup that will:
echo   1. Create a database trigger
echo   2. Auto-assign packages to ALL FUTURE clients
echo   3. Never needs to be run again
echo.

echo [1/2] Copying trigger SQL to clipboard...
type AUTO_ASSIGN_PACKAGE_TRIGGER.sql | clip
echo ✅ SQL copied to clipboard!
echo.

echo [2/2] Opening Supabase SQL Editor...
start https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new
echo ✅ SQL Editor opened!
echo.

echo ========================================
echo   INSTRUCTIONS:
echo ========================================
echo.
echo The SQL is ALREADY in your clipboard!
echo.
echo In the SQL Editor window that just opened:
echo   1. Click in the SQL editor area
echo   2. Press Ctrl+A (select all)
echo   3. Press Ctrl+V (paste)
echo   4. Click RUN button
echo.
echo ========================================
echo   WHAT THIS TRIGGER DOES:
echo ========================================
echo.
echo ✅ Automatically runs when a new client is created
echo ✅ Assigns a default "No Package" immediately
echo ✅ Works for ALL future clients forever
echo ✅ No code changes needed
echo ✅ Database handles it automatically
echo.
echo After this ONE-TIME setup:
echo   - Every new client gets a package automatically
echo   - No more "no package" errors
echo   - Works exactly like Khun bie's fix
echo   - Applied to ALL future clients
echo.

pause
