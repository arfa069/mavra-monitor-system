param(
    [switch]$BackendOnly,
    [switch]$NoCrawlerWorker,
    [switch]$NoBlogFrontend,
    [switch]$FlutterDev,
    [string]$PythonExe = "",
    [int]$CrawlerConcurrency = 3
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $projectRoot "backend"
$frontendDir = Join-Path $projectRoot "frontend"
$frontendBuildDir = Join-Path $frontendDir "build\web"
$blogFrontendDir = Join-Path $projectRoot "blog-frontend"
$backendLogDir = Join-Path $backendDir "logs"
$workerLog = Join-Path $backendLogDir "crawler-worker.log"
$defaultPythonExe = Join-Path $backendDir ".venv\Scripts\python.exe"

function Get-PortUsage {
    param([int]$Port)
    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($connections) {
        $results = @()
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $procName = if ($proc) { $proc.ProcessName } else { "Unknown" }
            $results += [PSCustomObject]@{
                PID = $conn.OwningProcess
                ProcessName = $procName
                LocalAddress = $conn.LocalAddress
                State = $conn.State
            }
        }
        return $results
    }
    return $null
}

function Close-ServiceWindows {
    $keywords = @("uvicorn", "flutter", "http.server", "npm", "next", "node", "python", "crawler")
    $toClose = @()

    $procs = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match "powershell|pwsh|cmd" -and $_.CommandLine
    }

    foreach ($proc in $procs) {
        $cmdLine = $proc.CommandLine
        $matched = $false
        foreach ($kw in $keywords) {
            if ($cmdLine -match $kw) {
                $matched = $true
                break
            }
        }
        if ($matched -and $proc.ProcessId -ne $PID) {
            $toClose += $proc.ProcessId
        }
    }

    foreach ($id in $toClose) {
        $p = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "  Closing window: $($p.ProcessName) (PID: $id)" -ForegroundColor DarkGray
            $p.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 100
            if (-not ($p.HasExited)) {
                $p.Kill()
            }
        }
    }
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Price Monitor Launcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = $defaultPythonExe
}

if (-not (Test-Path -LiteralPath $PythonExe)) {
    throw "Python executable not found: $PythonExe. Run 'cd backend; uv sync --extra dev' first, or pass -PythonExe explicitly."
}

if ($CrawlerConcurrency -lt 1) {
    throw "CrawlerConcurrency must be >= 1"
}

if (-not (Test-Path -LiteralPath $backendLogDir)) {
    New-Item -ItemType Directory -Path $backendLogDir | Out-Null
}

$frontendIndex = Join-Path $frontendBuildDir "index.html"
if (-not $BackendOnly -and -not $FlutterDev -and -not (Test-Path -LiteralPath $frontendIndex)) {
    throw "Flutter Web build not found: $frontendIndex. Run 'cd frontend; flutter build web --dart-define=API_BASE_URL=http://localhost:8000/api/v1' first, or pass -FlutterDev."
}

Write-Host ""
Write-Host "[Check] Scanning port usage..." -ForegroundColor Cyan

$portIssues = @()

$frontendPort = Get-PortUsage -Port 3000
if ($frontendPort) {
    $portIssues += [PSCustomObject]@{
        Port = 3000
        Service = "Frontend"
        Info = $frontendPort
    }
}

$blogPort = Get-PortUsage -Port 3001
if ($blogPort -and -not $NoBlogFrontend -and -not $BackendOnly) {
    $portIssues += [PSCustomObject]@{
        Port = 3001
        Service = "Blog Frontend"
        Info = $blogPort
    }
}

$backendPort = Get-PortUsage -Port 8000
if ($backendPort) {
    $portIssues += [PSCustomObject]@{
        Port = 8000
        Service = "Backend"
        Info = $backendPort
    }
}

# 检查已有 Crawler Worker 进程
$workerProcs = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "python" -and $_.CommandLine -match "app\.workers\.crawler"
}

if ($portIssues -or $workerProcs) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Processes in use - closing windows" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    Close-ServiceWindows

    foreach ($issue in $portIssues) {
        foreach ($p in $issue.Info) {
            if ($p.State -eq "Listen") {
                Write-Host "  Stopping: $($p.ProcessName) (PID: $($p.PID))" -ForegroundColor DarkGray
                Stop-Process -Id $p.PID -Force -ErrorAction SilentlyContinue
            }
        }
    }

    foreach ($proc in $workerProcs) {
        if ($proc.ProcessId -ne $PID) {
            Write-Host "  Stopping worker: $($proc.Name) (PID: $($proc.ProcessId))" -ForegroundColor DarkGray
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    Start-Sleep -Milliseconds 500
}

Write-Host "  [OK] Port 3000 (Frontend): Free" -ForegroundColor Green
if (-not $NoBlogFrontend -and -not $BackendOnly) {
    Write-Host "  [OK] Port 3001 (Blog):     Free" -ForegroundColor Green
}
Write-Host "  [OK] Port 8000 (Backend):  Free" -ForegroundColor Green
Write-Host "  [OK] Crawler Worker:        Free" -ForegroundColor Green

Write-Host ""
Write-Host "[Backend] Starting..." -ForegroundColor Cyan
$backendCmd = "Set-Location `"$backendDir`"; & `"$PythonExe`" -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
Write-Host "[Backend] http://localhost:8000" -ForegroundColor Cyan
Write-Host "[Backend] Python: $PythonExe" -ForegroundColor DarkGray

if (-not $NoCrawlerWorker) {
    Write-Host ""
    Write-Host "[Crawler Worker] Starting..." -ForegroundColor Cyan
    $workerCmd = "Set-Location `"$backendDir`"; Start-Transcript -Path `"$workerLog`" -Append | Out-Null; & `"$PythonExe`" -m app.workers.crawler --kind all --concurrency $CrawlerConcurrency; Stop-Transcript | Out-Null"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $workerCmd
    Write-Host "[Crawler Worker] $PythonExe -m app.workers.crawler --kind all --concurrency $CrawlerConcurrency" -ForegroundColor Cyan
    Write-Host "[Crawler Worker] Log: $workerLog" -ForegroundColor DarkGray
}

if (-not $BackendOnly) {
    Write-Host ""
    Write-Host "[Frontend] Starting..." -ForegroundColor Magenta
    if ($FlutterDev) {
        $frontendCmd = "Set-Location `"$frontendDir`"; flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api/v1"
        Write-Host "[Frontend] Flutter dev server requested with -FlutterDev" -ForegroundColor DarkGray
    }
    else {
        $frontendCmd = "Set-Location `"$frontendDir`"; & `"$PythonExe`" -m http.server 3000 --bind 127.0.0.1 --directory `"$frontendBuildDir`""
        Write-Host "[Frontend] Serving Flutter Web build from $frontendBuildDir" -ForegroundColor DarkGray
    }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
    Write-Host "[Frontend] http://localhost:3000" -ForegroundColor Magenta

    if (-not $NoBlogFrontend -and (Test-Path $blogFrontendDir)) {
        Write-Host ""
        Write-Host "[Blog] Starting..." -ForegroundColor Yellow
        $blogCmd = "Set-Location `"$blogFrontendDir`"; npm run dev -- --port 3001"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $blogCmd
        Write-Host "[Blog] http://localhost:3001/blog" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Tip: Use -BackendOnly for backend only, -FlutterDev for Flutter dev server, -NoCrawlerWorker to skip worker, -NoBlogFrontend to skip the public blog, -CrawlerConcurrency N to override worker concurrency" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Services started." -ForegroundColor Yellow
Write-Host "  Close windows to stop." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
