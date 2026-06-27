param(
    [switch]$BackendOnly,
    [switch]$NoCrawlerWorker,
    [switch]$NoBlogFrontend,
    [switch]$ChromeDev,
    [switch]$StaticFrontend,
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
    param([string[]]$Keywords)

    $toClose = @()

    $procs = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match "powershell|pwsh|cmd" -and $_.CommandLine
    }

    foreach ($proc in $procs) {
        $cmdLine = $proc.CommandLine
        $matched = $false
        foreach ($kw in $Keywords) {
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

function Test-PythonImports {
    param([string]$PythonExe)

    & $PythonExe -c "import sqlalchemy, uvicorn" *> $null
    return $LASTEXITCODE -eq 0
}

function Ensure-BackendPython {
    param(
        [string]$PythonExe,
        [string]$DefaultPythonExe,
        [string]$BackendDir
    )

    $usesDefaultPython = [string]::IsNullOrWhiteSpace($PythonExe) -or ($PythonExe -eq $DefaultPythonExe)
    if ([string]::IsNullOrWhiteSpace($PythonExe)) {
        $PythonExe = $DefaultPythonExe
    }

    $pythonExists = Test-Path -LiteralPath $PythonExe
    $pythonReady = $pythonExists -and (Test-PythonImports -PythonExe $PythonExe)

    if (-not $pythonReady) {
        if (-not $usesDefaultPython) {
            throw "Python executable is missing backend dependencies: $PythonExe. Run 'cd backend; uv sync --extra dev' or pass -PythonExe pointing to a prepared venv."
        }

        $uvCommand = Get-Command uv -ErrorAction SilentlyContinue
        if (-not $uvCommand) {
            throw "Python executable not found or missing backend dependencies: $PythonExe. 'uv' was not found, so run 'cd backend; uv sync --extra dev' manually first."
        }

        Write-Host "[Backend] Syncing backend environment with uv..." -ForegroundColor Cyan
        Push-Location $BackendDir
        try {
            & $uvCommand.Source sync --extra dev
            if ($LASTEXITCODE -ne 0) {
                throw "uv sync --extra dev failed."
            }
        }
        finally {
            Pop-Location
        }

        if (-not (Test-Path -LiteralPath $DefaultPythonExe)) {
            throw "Backend Python executable still not found after uv sync: $DefaultPythonExe"
        }
        if (-not (Test-PythonImports -PythonExe $DefaultPythonExe)) {
            throw "Backend virtual environment is still missing sqlalchemy or uvicorn after uv sync."
        }

        $PythonExe = $DefaultPythonExe
    }

    return $PythonExe
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Mavra Flutter Launcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if ($StaticFrontend -and ($ChromeDev -or $FlutterDev)) {
    throw "Choose one frontend mode: default web-server, -ChromeDev, or -StaticFrontend."
}

if ([string]::IsNullOrWhiteSpace($PythonExe)) {
    $PythonExe = $defaultPythonExe
}

$PythonExe = Ensure-BackendPython -PythonExe $PythonExe -DefaultPythonExe $defaultPythonExe -BackendDir $backendDir

if ($CrawlerConcurrency -lt 1) {
    throw "CrawlerConcurrency must be >= 1"
}

if (-not (Test-Path -LiteralPath $backendLogDir)) {
    New-Item -ItemType Directory -Path $backendLogDir | Out-Null
}

$frontendIndex = Join-Path $frontendBuildDir "index.html"
if (-not $BackendOnly -and $StaticFrontend -and -not (Test-Path -LiteralPath $frontendIndex)) {
    throw "Flutter Web build not found: $frontendIndex. Run 'cd frontend; flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1' first, or omit -StaticFrontend."
}

Write-Host ""
Write-Host "[Check] Scanning port usage..." -ForegroundColor Cyan

$portIssues = @()

$managedWindowKeywords = @("uvicorn")

if (-not $BackendOnly) {
    $managedWindowKeywords += "flutter"
    if ($StaticFrontend) {
        $managedWindowKeywords += "http.server"
    }

    $frontendPort = Get-PortUsage -Port 3000
    if ($frontendPort) {
        $portIssues += [PSCustomObject]@{
            Port = 3000
            Service = "Frontend"
            Info = $frontendPort
        }
    }
}

if (-not $NoBlogFrontend -and -not $BackendOnly) {
    $managedWindowKeywords += @("npm", "next", "node")

    $blogPort = Get-PortUsage -Port 3001
    if ($blogPort) {
        $portIssues += [PSCustomObject]@{
            Port = 3001
            Service = "Blog Frontend"
            Info = $blogPort
        }
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

$workerProcs = @()
if (-not $NoCrawlerWorker -and -not $BackendOnly) {
    $managedWindowKeywords += "app\.workers\.crawler"
    $workerProcs = Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match "python" -and $_.CommandLine -match "app\.workers\.crawler"
    }
}

if ($portIssues -or $workerProcs) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Processes in use - closing windows" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    Close-ServiceWindows -Keywords $managedWindowKeywords

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

if (-not $BackendOnly) {
    Write-Host "  [OK] Port 3000 (Frontend): Free" -ForegroundColor Green
}
if (-not $NoBlogFrontend -and -not $BackendOnly) {
    Write-Host "  [OK] Port 3001 (Blog):     Free" -ForegroundColor Green
}
Write-Host "  [OK] Port 8000 (Backend):  Free" -ForegroundColor Green
if (-not $NoCrawlerWorker -and -not $BackendOnly) {
    Write-Host "  [OK] Crawler Worker:        Free" -ForegroundColor Green
}

Write-Host ""
Write-Host "[Backend] Starting..." -ForegroundColor Cyan
$backendCmd = "Set-Location `"$backendDir`"; & `"$PythonExe`" -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
Write-Host "[Backend] http://localhost:8000" -ForegroundColor Cyan
Write-Host "[Backend] Python: $PythonExe" -ForegroundColor DarkGray

if (-not $NoCrawlerWorker -and -not $BackendOnly) {
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
        Write-Host "[Frontend] -FlutterDev is kept as a compatibility alias. Default web-server is recommended; use -ChromeDev for Flutter Inspector." -ForegroundColor DarkGray
    }

    if ($StaticFrontend) {
        $frontendCmd = "Set-Location `"$frontendDir`"; & `"$PythonExe`" -m http.server 3000 --bind 127.0.0.1 --directory `"$frontendBuildDir`""
        Write-Host "[Frontend] Serving Flutter Web build from $frontendBuildDir" -ForegroundColor DarkGray
    }
    elseif ($ChromeDev) {
        $frontendCmd = "Set-Location `"$frontendDir`"; flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"
        Write-Host "[Frontend] Flutter Chrome debug mode requested with -ChromeDev" -ForegroundColor DarkGray
    }
    else {
        $frontendCmd = "Set-Location `"$frontendDir`"; flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"
        Write-Host "[Frontend] Flutter web-server on 127.0.0.1:3000" -ForegroundColor DarkGray
    }
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
    Write-Host "[Frontend] http://127.0.0.1:3000" -ForegroundColor Magenta

    if (-not $NoBlogFrontend -and (Test-Path $blogFrontendDir)) {
        Write-Host ""
        Write-Host "[Blog] Starting..." -ForegroundColor Yellow
        $blogCmd = "Set-Location `"$blogFrontendDir`"; npm run dev -- --port 3001"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $blogCmd
        Write-Host "[Blog] http://127.0.0.1:3001/blog" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Tip: default frontend uses Flutter web-server. Use -ChromeDev for Flutter DevTools/Inspector, -StaticFrontend to serve frontend/build/web, -NoCrawlerWorker to skip worker, -NoBlogFrontend to skip the public blog, or -BackendOnly for backend only." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Services started." -ForegroundColor Yellow
Write-Host "  Close windows to stop." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
