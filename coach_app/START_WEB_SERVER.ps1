Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Web Server + Cloudflare Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$PORT = 8080
$BUILD_DIR = "build/web"

# Check if build exists
if (-Not (Test-Path $BUILD_DIR)) {
    Write-Host "[ERROR] build/web directory not found!" -ForegroundColor Red
    Write-Host "Run 'flutter build web' first!" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/3] Checking for existing processes on port $PORT..." -ForegroundColor Yellow

# Kill any existing processes on port 8080
$processes = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique

if ($processes) {
    Write-Host "  Found processes using port $PORT, stopping them..." -ForegroundColor Yellow
    foreach ($pid in $processes) {
        try {
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Write-Host "  Stopped process: $pid" -ForegroundColor Green
        } catch {
            Write-Host "  Could not stop process: $pid" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 2
}

Write-Host "[2/3] Starting HTTP server on port $PORT..." -ForegroundColor Yellow
Write-Host "  Serving from: $BUILD_DIR" -ForegroundColor Cyan

# Change to build/web directory and start Python HTTP server
cd $BUILD_DIR

# Start Python HTTP server in background
$serverJob = Start-Job -ScriptBlock {
    param($port)
    python -m http.server $port
} -ArgumentList $PORT

Start-Sleep -Seconds 3

# Verify server is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$PORT" -TimeoutSec 3 -UseBasicParsing
    Write-Host "  ✓ Web server running on http://localhost:$PORT" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Web server failed to start!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Stop-Job $serverJob
    Remove-Job $serverJob
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[3/3] Starting Cloudflare Tunnel..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Your app will be accessible via the URL below" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start Cloudflare tunnel (foreground)
cloudflared tunnel --url http://localhost:$PORT

# Cleanup when tunnel stops
Write-Host ""
Write-Host "Cloudflare tunnel stopped. Cleaning up..." -ForegroundColor Yellow
Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -ErrorAction SilentlyContinue
