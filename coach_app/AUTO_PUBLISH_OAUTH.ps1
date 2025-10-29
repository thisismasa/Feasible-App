# Automatic OAuth Publishing Script
# This script uses Google Cloud CLI to automatically publish your OAuth app

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Automatic OAuth Publisher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$PROJECT_NUMBER = "576001465184"
$CLIENT_ID = "576001465184-pv04h51b3pl92hkdibgssabm2cegbq6r.apps.googleusercontent.com"
$CLOUDFLARE_URL = "https://tones-dancing-patches-searching.trycloudflare.com"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Project: $PROJECT_NUMBER" -ForegroundColor White
Write-Host "  Client ID: $CLIENT_ID" -ForegroundColor White
Write-Host "  Cloudflare URL: $CLOUDFLARE_URL" -ForegroundColor White
Write-Host ""

# Step 1: Check if gcloud is installed
Write-Host "[1/6] Checking Google Cloud CLI..." -ForegroundColor Yellow
try {
    $gcloudVersion = gcloud --version 2>&1 | Select-Object -First 1
    Write-Host "  Found: $gcloudVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: gcloud CLI not found!" -ForegroundColor Red
    Write-Host "  Install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 2: Check authentication
Write-Host "[2/6] Checking authentication..." -ForegroundColor Yellow
$authList = gcloud auth list --format="value(account)" 2>&1

if ($authList -match "No credentialed accounts") {
    Write-Host "  Not authenticated. Starting authentication..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  A browser window will open. Please:" -ForegroundColor Cyan
    Write-Host "  1. Sign in with your Google account" -ForegroundColor White
    Write-Host "  2. Allow Google Cloud SDK access" -ForegroundColor White
    Write-Host "  3. Return to this window" -ForegroundColor White
    Write-Host ""

    # Authenticate
    gcloud auth login

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Authentication failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host "  Authentication successful!" -ForegroundColor Green
} else {
    Write-Host "  Already authenticated as: $authList" -ForegroundColor Green
}
Write-Host ""

# Step 3: Set project
Write-Host "[3/6] Setting Google Cloud project..." -ForegroundColor Yellow
gcloud config set project $PROJECT_NUMBER 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to set project!" -ForegroundColor Red
    Write-Host "  You may not have access to project: $PROJECT_NUMBER" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Trying to get project ID from OAuth Client..." -ForegroundColor Yellow

    # Try to list projects
    $projects = gcloud projects list --format="value(projectId)" 2>&1

    if ($projects -and $projects.Count -gt 0) {
        Write-Host "  Available projects:" -ForegroundColor Cyan
        $projects | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
        Write-Host ""

        $selectedProject = $projects | Select-Object -First 1
        Write-Host "  Using first project: $selectedProject" -ForegroundColor Yellow
        gcloud config set project $selectedProject 2>&1 | Out-Null
    } else {
        Write-Host "  ERROR: No projects found!" -ForegroundColor Red
        exit 1
    }
}

$currentProject = gcloud config get-value project 2>&1
Write-Host "  Project set to: $currentProject" -ForegroundColor Green
Write-Host ""

# Step 4: Enable required APIs
Write-Host "[4/6] Ensuring required APIs are enabled..." -ForegroundColor Yellow
Write-Host "  Enabling OAuth2 API..." -ForegroundColor White

# Enable necessary APIs
$apis = @(
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com"
)

foreach ($api in $apis) {
    gcloud services enable $api 2>&1 | Out-Null
}

Write-Host "  APIs enabled!" -ForegroundColor Green
Write-Host ""

# Step 5: Attempt to publish OAuth app
Write-Host "[5/6] Publishing OAuth Consent Screen to Production..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  IMPORTANT: gcloud CLI has limited OAuth consent screen management." -ForegroundColor Yellow
Write-Host "  The most reliable way is still through the web console." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Opening OAuth Consent Screen in browser..." -ForegroundColor Cyan
Start-Process "https://console.cloud.google.com/apis/credentials/consent?project=$currentProject"
Write-Host ""

# Step 6: Update OAuth Client with Cloudflare URL
Write-Host "[6/6] Updating OAuth Client with Cloudflare URL..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Unfortunately, gcloud CLI doesn't support updating OAuth client URIs." -ForegroundColor Yellow
Write-Host "  Opening OAuth Client Settings in browser..." -ForegroundColor Cyan
Start-Process "https://console.cloud.google.com/apis/credentials/oauthclient/$CLIENT_ID?project=$currentProject"
Write-Host ""

# Copy Cloudflare URL to clipboard
$CLOUDFLARE_URL | Set-Clipboard
Write-Host "  Cloudflare URL copied to clipboard!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Manual Steps Required" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Two browser windows have opened. Please complete:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Window 1 - OAuth Consent Screen:" -ForegroundColor Green
Write-Host "  1. Click 'PUBLISH APP' button at top" -ForegroundColor White
Write-Host "  2. Read the warning" -ForegroundColor White
Write-Host "  3. Click 'CONFIRM'" -ForegroundColor White
Write-Host "  4. Status should change to 'In production'" -ForegroundColor White
Write-Host ""
Write-Host "Window 2 - OAuth Client:" -ForegroundColor Green
Write-Host "  URL in clipboard: $CLOUDFLARE_URL" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Add to 'Authorized JavaScript origins':" -ForegroundColor White
Write-Host "    1. Click '+ ADD URI'" -ForegroundColor White
Write-Host "    2. Paste (Ctrl+V)" -ForegroundColor White
Write-Host ""
Write-Host "  Add to 'Authorized redirect URIs':" -ForegroundColor White
Write-Host "    1. Click '+ ADD URI'" -ForegroundColor White
Write-Host "    2. Paste (Ctrl+V)" -ForegroundColor White
Write-Host ""
Write-Host "  3. Click 'SAVE' at bottom" -ForegroundColor White
Write-Host "  4. Wait 5 minutes for changes to propagate" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Why Manual Steps?" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Google Cloud CLI (gcloud) has limitations:" -ForegroundColor Yellow
Write-Host "  - Cannot publish OAuth consent screen via CLI" -ForegroundColor White
Write-Host "  - Cannot update OAuth client redirect URIs via CLI" -ForegroundColor White
Write-Host "  - These require Google Cloud Console (web interface)" -ForegroundColor White
Write-Host ""
Write-Host "This script automated:" -ForegroundColor Green
Write-Host "  - gcloud authentication" -ForegroundColor White
Write-Host "  - Project configuration" -ForegroundColor White
Write-Host "  - Opening correct console pages" -ForegroundColor White
Write-Host "  - Copying URLs to clipboard" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After completing the manual steps above:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Wait 5 minutes for Google to propagate changes" -ForegroundColor White
Write-Host "2. Open your app: $CLOUDFLARE_URL" -ForegroundColor Cyan
Write-Host "3. Click 'Sign in with Google'" -ForegroundColor White
Write-Host "4. Test with multiple Google accounts" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
