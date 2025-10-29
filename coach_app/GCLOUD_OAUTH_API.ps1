# Advanced OAuth Configuration using Google Cloud REST API
# This attempts to use the REST API directly to publish OAuth app

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OAuth API Automation (Advanced)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$PROJECT_NUMBER = "576001465184"
$CLIENT_ID = "576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r"
$CLOUDFLARE_URL = "https://tones-dancing-patches-searching.trycloudflare.com"

Write-Host "Attempting advanced API-based configuration..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Authenticate and get access token
Write-Host "[1/4] Getting OAuth access token..." -ForegroundColor Yellow

try {
    # Try to get access token
    $token = gcloud auth print-access-token 2>&1

    if ($LASTEXITCODE -ne 0 -or $token -match "ERROR") {
        Write-Host "  Not authenticated. Running authentication..." -ForegroundColor Yellow
        gcloud auth login --quiet
        $token = gcloud auth print-access-token 2>&1
    }

    if ($token -and $token -notmatch "ERROR") {
        Write-Host "  Access token obtained!" -ForegroundColor Green
    } else {
        throw "Failed to get access token"
    }
} catch {
    Write-Host "  ERROR: Could not get access token" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Get current OAuth client configuration
Write-Host "[2/4] Fetching current OAuth client configuration..." -ForegroundColor Yellow

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Try to get OAuth client details
$clientUrl = "https://www.googleapis.com/oauth2/v2/clients/$CLIENT_ID"

try {
    $response = Invoke-RestMethod -Uri $clientUrl -Headers $headers -Method Get -ErrorAction SilentlyContinue
    Write-Host "  Current configuration retrieved!" -ForegroundColor Green
    Write-Host "  Client ID: $($response.client_id)" -ForegroundColor White
} catch {
    Write-Host "  Note: OAuth Client API access is limited" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Update OAuth client with Cloudflare URL
Write-Host "[3/4] Attempting to update OAuth client..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  IMPORTANT LIMITATION:" -ForegroundColor Yellow
Write-Host "  The OAuth2 Client API requires special permissions and" -ForegroundColor White
Write-Host "  is primarily designed for internal Google use." -ForegroundColor White
Write-Host ""
Write-Host "  For security reasons, Google requires manual consent screen" -ForegroundColor White
Write-Host "  publishing through the Cloud Console." -ForegroundColor White
Write-Host ""

# Step 4: Use gcloud to try publishing (if possible)
Write-Host "[4/4] Checking for alternative automation methods..." -ForegroundColor Yellow
Write-Host ""

# Try using gcloud alpha/beta features (if available)
Write-Host "  Checking gcloud components..." -ForegroundColor White
$components = gcloud components list --format="value(id,state)" 2>&1

if ($components -match "alpha.*Not Installed") {
    Write-Host "  Installing gcloud alpha components (may help with OAuth management)..." -ForegroundColor Yellow
    Write-Host "  This may take a few minutes..." -ForegroundColor Gray
    # Note: Commenting out as this requires user confirmation
    # gcloud components install alpha --quiet
    Write-Host "  Skipped - requires manual installation" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  API Limitations Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Google Cloud Platform restricts these operations:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Cannot automate via API:" -ForegroundColor Red
Write-Host "    - Publishing OAuth consent screen" -ForegroundColor White
Write-Host "    - Updating OAuth client redirect URIs" -ForegroundColor White
Write-Host "    - Modifying JavaScript origins" -ForegroundColor White
Write-Host ""
Write-Host "  Reason:" -ForegroundColor Yellow
Write-Host "    Google requires manual approval through Cloud Console" -ForegroundColor White
Write-Host "    for security and compliance purposes." -ForegroundColor White
Write-Host ""
Write-Host "  Can automate via API:" -ForegroundColor Green
Write-Host "    - Authentication (gcloud auth login)" -ForegroundColor White
Write-Host "    - Project selection" -ForegroundColor White
Write-Host "    - Opening correct console pages" -ForegroundColor White
Write-Host "    - Reading current configuration" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Recommended Approach" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Best practice for publishing OAuth app:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Use the web console (most reliable):" -ForegroundColor Green
Write-Host "   - Run: AUTO_PUBLISH_OAUTH.ps1" -ForegroundColor Cyan
Write-Host "   - Follow guided steps in browser" -ForegroundColor White
Write-Host "   - Takes 2-3 minutes" -ForegroundColor White
Write-Host ""
Write-Host "2. For production apps (later):" -ForegroundColor Green
Write-Host "   - Use Terraform or Deployment Manager" -ForegroundColor White
Write-Host "   - Store configuration as code" -ForegroundColor White
Write-Host "   - Version control your infrastructure" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening web console for manual configuration..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Open the necessary pages
Start-Process "https://console.cloud.google.com/apis/credentials/consent"
Start-Sleep -Seconds 1
Start-Process "https://console.cloud.google.com/apis/credentials/oauthclient/$CLIENT_ID.apps.googleusercontent.com"

$CLOUDFLARE_URL | Set-Clipboard
Write-Host "Cloudflare URL copied to clipboard!" -ForegroundColor Green
Write-Host ""

Write-Host "Complete the manual steps in the opened browser windows." -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
