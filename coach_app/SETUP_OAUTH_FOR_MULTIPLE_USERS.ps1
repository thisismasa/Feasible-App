# Google OAuth Setup for Multiple Users
# This script helps you configure OAuth for Cloudflare tunnel

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Google OAuth Multi-User Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detect current Cloudflare URL (if tunnel is running)
$cloudflareUrl = "https://tones-dancing-patches-searching.trycloudflare.com"

Write-Host "Your Current Cloudflare URL:" -ForegroundColor Yellow
Write-Host $cloudflareUrl -ForegroundColor Green
Write-Host ""

# Copy to clipboard
$cloudflareUrl | Set-Clipboard
Write-Host "URL copied to clipboard!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Problem:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Google OAuth is configured for localhost only." -ForegroundColor Yellow
Write-Host "When users try to sign in via Cloudflare tunnel," -ForegroundColor Yellow
Write-Host "they get 'Access Blocked' error." -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Solution:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Choose your approach:" -ForegroundColor Yellow
Write-Host ""
Write-Host "[1] PUBLISH APP (Recommended) - Allow ANY Google user" -ForegroundColor Green
Write-Host "    - Best for multiple users" -ForegroundColor Gray
Write-Host "    - Works with any Cloudflare URL" -ForegroundColor Gray
Write-Host "    - Takes 1 minute" -ForegroundColor Gray
Write-Host ""
Write-Host "[2] ADD TEST USERS - Restrict to specific emails" -ForegroundColor Yellow
Write-Host "    - Good for closed testing" -ForegroundColor Gray
Write-Host "    - Max 100 users" -ForegroundColor Gray
Write-Host "    - Need to update for each new user" -ForegroundColor Gray
Write-Host ""
Write-Host "[3] ADD CLOUDFLARE URL - Quick fix for current session" -ForegroundColor Cyan
Write-Host "    - Works for current URL only" -ForegroundColor Gray
Write-Host "    - Need to update when tunnel restarts" -ForegroundColor Gray
Write-Host ""
Write-Host "[4] DO ALL - Complete setup" -ForegroundColor Magenta
Write-Host "    - Publish app + Add URL" -ForegroundColor Gray
Write-Host "    - Best for production-ready setup" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Opening Google Cloud Console..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($choice) {
    "1" {
        Write-Host "Opening OAuth Consent Screen..." -ForegroundColor Yellow
        Write-Host ""
        Start-Process "https://console.cloud.google.com/apis/credentials/consent"
        Write-Host ""
        Write-Host "Instructions:" -ForegroundColor Green
        Write-Host "1. Click 'PUBLISH APP' button at top" -ForegroundColor White
        Write-Host "2. Read the warning" -ForegroundColor White
        Write-Host "3. Click 'CONFIRM'" -ForegroundColor White
        Write-Host "4. Done! Any Google user can now sign in" -ForegroundColor White
        Write-Host ""
    }
    "2" {
        Write-Host "Opening OAuth Consent Screen..." -ForegroundColor Yellow
        Write-Host ""
        Start-Process "https://console.cloud.google.com/apis/credentials/consent"
        Write-Host ""
        Write-Host "Instructions:" -ForegroundColor Green
        Write-Host "1. Scroll to 'Test users' section" -ForegroundColor White
        Write-Host "2. Click '+ ADD USERS'" -ForegroundColor White
        Write-Host "3. Enter Gmail addresses (one per line)" -ForegroundColor White
        Write-Host "4. Click 'SAVE'" -ForegroundColor White
        Write-Host ""
    }
    "3" {
        Write-Host "Opening OAuth Client Settings..." -ForegroundColor Yellow
        Write-Host ""
        Start-Process "https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com"
        Write-Host ""
        Write-Host "Cloudflare URL (already in clipboard):" -ForegroundColor Green
        Write-Host $cloudflareUrl -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Instructions:" -ForegroundColor Green
        Write-Host "1. Scroll to 'Authorized JavaScript origins'" -ForegroundColor White
        Write-Host "2. Click '+ ADD URI'" -ForegroundColor White
        Write-Host "3. Paste (Ctrl+V): $cloudflareUrl" -ForegroundColor White
        Write-Host "4. Scroll to 'Authorized redirect URIs'" -ForegroundColor White
        Write-Host "5. Click '+ ADD URI'" -ForegroundColor White
        Write-Host "6. Paste (Ctrl+V): $cloudflareUrl" -ForegroundColor White
        Write-Host "7. Click 'SAVE' at bottom" -ForegroundColor White
        Write-Host "8. Wait 5 minutes" -ForegroundColor Yellow
        Write-Host ""
    }
    "4" {
        Write-Host "Opening both pages..." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 1
        Start-Process "https://console.cloud.google.com/apis/credentials/consent"
        Start-Sleep -Seconds 2
        Start-Process "https://console.cloud.google.com/apis/credentials/oauthclient/576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com"
        Write-Host ""
        Write-Host "Page 1 - OAuth Consent Screen:" -ForegroundColor Green
        Write-Host "  1. Click 'PUBLISH APP' button" -ForegroundColor White
        Write-Host "  2. Click 'CONFIRM'" -ForegroundColor White
        Write-Host ""
        Write-Host "Page 2 - OAuth Client:" -ForegroundColor Green
        Write-Host "  Cloudflare URL (in clipboard): $cloudflareUrl" -ForegroundColor Cyan
        Write-Host "  1. Add to 'Authorized JavaScript origins'" -ForegroundColor White
        Write-Host "  2. Add to 'Authorized redirect URIs'" -ForegroundColor White
        Write-Host "  3. Click 'SAVE'" -ForegroundColor White
        Write-Host ""
    }
    default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        exit
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  After Configuration:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Wait 5 minutes for changes to propagate" -ForegroundColor Yellow
Write-Host "2. Open your app:" -ForegroundColor Yellow
Write-Host "   $cloudflareUrl" -ForegroundColor Cyan
Write-Host "3. Click 'Sign in with Google'" -ForegroundColor Yellow
Write-Host "4. Test with multiple Google accounts" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
