# Flutter Web + Cloudflare Tunnel Runner
# This script starts Flutter web server and creates a Cloudflare tunnel

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Flutter Web + Cloudflare Tunnel" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Step 1: Check if Flutter is available
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "Found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Step 2: Check if cloudflared is available
Write-Host "Checking Cloudflare Tunnel installation..." -ForegroundColor Yellow
try {
    $cloudflaredVersion = cloudflared --version 2>&1 | Select-Object -First 1
    Write-Host "Found: $cloudflaredVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: cloudflared not found. Please install it first." -ForegroundColor Red
    Write-Host "Run: scoop install cloudflared" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Starting Services..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Step 3: Start Flutter web server in background
Write-Host "Starting Flutter Web Server on port 8080..." -ForegroundColor Yellow
$flutterJob = Start-Job -ScriptBlock {
    Set-Location $using:PSScriptRoot
    flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
}

Write-Host "Waiting for Flutter web server to initialize (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 4: Check if port 8080 is listening
Write-Host "Checking if web server is running..." -ForegroundColor Yellow
$portCheck = netstat -an | Select-String ":8080"
if ($portCheck) {
    Write-Host "Web server is running on port 8080!" -ForegroundColor Green
} else {
    Write-Host "WARNING: Port 8080 may not be listening yet. Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Starting Cloudflare Tunnel..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your app will be accessible via the URL shown below." -ForegroundColor Green
Write-Host "Open this URL on your iPhone's Safari browser!" -ForegroundColor Green
Write-Host ""

# Step 5: Start Cloudflare tunnel (this runs in foreground)
try {
    cloudflared tunnel --url http://localhost:8080
} finally {
    # Cleanup: Stop Flutter job when tunnel stops
    Write-Host ""
    Write-Host "Stopping Flutter web server..." -ForegroundColor Yellow
    Stop-Job -Job $flutterJob
    Remove-Job -Job $flutterJob
    Write-Host "Cleanup complete!" -ForegroundColor Green
}
