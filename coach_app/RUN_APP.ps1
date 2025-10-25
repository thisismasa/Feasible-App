# Coach App Runner - PowerShell Script
# This script runs your Flutter app without PATH issues

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Green
Write-Host "   Starting Coach App..." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Navigate to script directory
Set-Location $PSScriptRoot

# Flutter path
$flutterPath = "C:\src\flutter\bin\flutter.bat"

# Check if Flutter exists
Write-Host "[1/3] Checking Flutter..." -ForegroundColor Yellow
if (-not (Test-Path $flutterPath)) {
    Write-Host "ERROR: Flutter not found at $flutterPath" -ForegroundColor Red
    Write-Host "Please check your Flutter installation." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

& $flutterPath --version
Write-Host "✓ Flutter found!" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "[2/3] Getting dependencies..." -ForegroundColor Yellow
& $flutterPath pub get
Write-Host "✓ Dependencies ready!" -ForegroundColor Green
Write-Host ""

# Run app
Write-Host "[3/3] Starting app on Chrome..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " TIP: Once running, press 'r' to hot reload" -ForegroundColor Cyan
Write-Host "      Press 'q' to quit" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

& $flutterPath run -d chrome

Read-Host "Press Enter to exit"

