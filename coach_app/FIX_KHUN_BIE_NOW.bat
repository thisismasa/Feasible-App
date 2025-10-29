@echo off
title Fix Khun bie Package - AUTOMATIC
color 0A

echo ========================================
echo   FIX KHUN BIE PACKAGE - AUTOMATIC
echo ========================================
echo.

echo [1/2] Copying SQL to clipboard...
type ASSIGN_KHUN_BIE_PACKAGE.sql | clip
echo ✅ SQL copied!
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
echo This will:
echo   ✅ Assign 1800 baht package to Khun bie
echo   ✅ Set status to active
echo   ✅ Give 1 session, valid for 30 days
echo   ✅ Verify it worked
echo.
echo After running, refresh your app and
echo Khun bie will appear with active package!
echo.

pause
