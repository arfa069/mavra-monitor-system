param(
    [string]$SshTarget = $(if ($env:PHONE_SSH_TARGET) { $env:PHONE_SSH_TARGET } else { "u0_a323@192.168.1.13" }),
    [int]$SshPort = $(if ($env:PHONE_SSH_PORT) { [int]$env:PHONE_SSH_PORT } else { 8022 }),
    [string]$RemoteDbHost = $(if ($env:PHONE_POSTGRES_HOST) { $env:PHONE_POSTGRES_HOST } else { "127.0.0.1" }),
    [int]$RemoteDbPort = $(if ($env:PHONE_POSTGRES_PORT) { [int]$env:PHONE_POSTGRES_PORT } else { 5432 }),
    [int]$LocalDbPort = $(if ($env:PHONE_LOCAL_DB_PORT) { [int]$env:PHONE_LOCAL_DB_PORT } else { 15432 }),
    [string]$RemoteProjectRoot = $(if ($env:PHONE_REMOTE_PROJECT_ROOT) { $env:PHONE_REMOTE_PROJECT_ROOT } else { "~/apps/mavra-monitor-system" }),
    [string]$DatabaseUrl = $env:PHONE_DATABASE_URL,
    [string]$DatabaseUser = $(if ($env:PHONE_POSTGRES_USER) { $env:PHONE_POSTGRES_USER } else { "postgres" }),
    [string]$DatabasePassword = $env:PHONE_POSTGRES_PASSWORD,
    [string]$DatabaseName = $(if ($env:PHONE_POSTGRES_DB) { $env:PHONE_POSTGRES_DB } else { "pricemonitor" }),
    [string]$SshPassword = $env:PHONE_SSH_PASSWORD,
    [string]$Kind = "all",
    [string[]]$Platform = @(),
    [int]$Concurrency = 1,
    [switch]$Once,
    [switch]$UseExistingTunnel
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connect = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne(1500, $false)) {
            return $false
        }
        $client.EndConnect($connect)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

function ConvertTo-PlainText {
    param([securestring]$SecureValue)

    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function New-DatabaseUrl {
    param(
        [string]$User,
        [string]$Password,
        [string]$HostName,
        [int]$Port,
        [string]$Database
    )

    $escapedUser = [uri]::EscapeDataString($User)
    $escapedPassword = [uri]::EscapeDataString($Password)
    $escapedDatabase = [uri]::EscapeDataString($Database)
    return "postgresql+asyncpg://${escapedUser}:${escapedPassword}@${HostName}:${Port}/${escapedDatabase}"
}

function Convert-DatabaseUrlForTunnel {
    param(
        [string]$RawValue,
        [int]$TunnelPort
    )

    $trimmed = $RawValue.Trim().Trim('"').Trim("'")
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return $null
    }
    $uriText = $trimmed -replace "^postgresql\+asyncpg://", "postgresql://"
    $uri = [Uri]$uriText
    $scheme = if ($trimmed.StartsWith("postgresql+asyncpg://")) { "postgresql+asyncpg" } else { $uri.Scheme }
    return "${scheme}://$($uri.UserInfo)@127.0.0.1:${TunnelPort}$($uri.AbsolutePath)"
}

function Get-LocalDatabaseUrlFromEnvFile {
    param(
        [string]$ProjectRoot,
        [int]$TunnelPort
    )

    foreach ($path in @(
        (Join-Path $ProjectRoot ".env"),
        (Join-Path $ProjectRoot "backend/.env")
    )) {
        if (-not (Test-Path $path)) {
            continue
        }
        $line = Select-String -Path $path -Pattern "^\s*DATABASE_URL\s*=" | Select-Object -First 1
        if (-not $line) {
            continue
        }
        $rawValue = ($line.Line -split "=", 2)[1].Trim().Trim('"').Trim("'")
        if ([string]::IsNullOrWhiteSpace($rawValue)) {
            continue
        }
        return Convert-DatabaseUrlForTunnel -RawValue $rawValue -TunnelPort $TunnelPort
    }
    return $null
}

function Get-ParamikoPython {
    foreach ($candidate in @("python", "py")) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if (-not $cmd) {
            continue
        }
        & $candidate -c "import paramiko" *> $null
        if ($LASTEXITCODE -eq 0) {
            return $candidate
        }
    }
    return $null
}

function Get-RemoteDatabaseUrlFromEnvFile {
    param(
        [string]$PythonCommand,
        [string]$Target,
        [int]$TargetPort,
        [string]$Password,
        [string]$ProjectRoot,
        [int]$TunnelPort
    )

    $targetParts = Split-SshTarget -Target $Target
    $helperPath = Join-Path ([System.IO.Path]::GetTempPath()) ("mavra-phone-read-env-{0}.py" -f ([guid]::NewGuid().ToString("N")))
    $helper = @'
import os
import sys

import paramiko

ssh_host = os.environ["PHONE_SSH_HOST"]
ssh_port = int(os.environ["PHONE_SSH_PORT"])
ssh_user = os.environ["PHONE_SSH_USER"]
ssh_password = os.environ["PHONE_SSH_PASSWORD"]
project_root = os.environ["PHONE_REMOTE_PROJECT_ROOT"]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    ssh_host,
    port=ssh_port,
    username=ssh_user,
    password=ssh_password,
    look_for_keys=False,
    allow_agent=False,
    timeout=10,
)

try:
    _stdin, stdout, _stderr = client.exec_command('printf "%s" "$HOME"', timeout=10)
    stdout.channel.recv_exit_status()
    home = stdout.read().decode("utf-8", errors="replace").strip()
    if project_root.startswith("~/"):
        project_root = f"{home}/{project_root[2:]}"
    elif project_root == "~":
        project_root = home
    elif project_root.startswith("$HOME/"):
        project_root = f"{home}/{project_root[6:]}"
    elif project_root == "$HOME":
        project_root = home

    sftp = client.open_sftp()
    value = ""
    for path in (f"{project_root}/.env", f"{project_root}/backend/.env"):
        try:
            with sftp.open(path, "r") as handle:
                for line in handle:
                    stripped = line.strip()
                    if not stripped or stripped.startswith("#") or "=" not in stripped:
                        continue
                    key, raw_value = stripped.split("=", 1)
                    if key.strip() == "DATABASE_URL":
                        value = raw_value.strip().strip('"').strip("'")
                        break
        except FileNotFoundError:
            continue
        if value:
            break
finally:
    try:
        sftp.close()
    except Exception:
        pass
    client.close()

if not value:
    print(f"DATABASE_URL not found under {project_root}/.env or {project_root}/backend/.env", file=sys.stderr)
    raise SystemExit(4)

print(value)
'@
    Set-Content -LiteralPath $helperPath -Value $helper -Encoding UTF8

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $PythonCommand
    $startInfo.Arguments = "`"$helperPath`""
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.Environment["PHONE_SSH_HOST"] = $targetParts.Host
    $startInfo.Environment["PHONE_SSH_PORT"] = "$TargetPort"
    $startInfo.Environment["PHONE_SSH_USER"] = $targetParts.User
    $startInfo.Environment["PHONE_SSH_PASSWORD"] = $Password
    $startInfo.Environment["PHONE_REMOTE_PROJECT_ROOT"] = $ProjectRoot

    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            if ($stderr) {
                Write-Host "[DB] Could not read phone .env: $stderr" -ForegroundColor Yellow
            }
            return $null
        }
        return Convert-DatabaseUrlForTunnel -RawValue $stdout -TunnelPort $TunnelPort
    }
    finally {
        Remove-Item -LiteralPath $helperPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-PostgresHealthcheck {
    param(
        [string]$BackendDir,
        [string]$DatabaseUrl,
        [int]$Attempts = 5
    )

    $probePath = Join-Path ([System.IO.Path]::GetTempPath()) ("mavra-postgres-healthcheck-{0}.py" -f ([guid]::NewGuid().ToString("N")))
    $probe = @'
import asyncio
import os
import sys
import warnings

import asyncpg

if sys.platform == "win32":
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())


async def main() -> int:
    database_url = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://", 1)
    try:
        connection = await asyncpg.connect(database_url, timeout=5)
    except Exception as exc:
        print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    try:
        await connection.execute("SELECT 1")
    finally:
        await connection.close()
    return 0


raise SystemExit(asyncio.run(main()))
'@
    Set-Content -LiteralPath $probePath -Value $probe -Encoding UTF8

    $oldDatabaseUrlForProbe = $env:DATABASE_URL
    $env:DATABASE_URL = $DatabaseUrl
    try {
        Push-Location $BackendDir
        try {
            for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
                if (Get-Command uv -ErrorAction SilentlyContinue) {
                    & uv run --extra dev python $probePath
                }
                elseif (Test-Path (Join-Path $BackendDir ".venv/Scripts/python.exe")) {
                    & (Join-Path $BackendDir ".venv/Scripts/python.exe") $probePath
                }
                else {
                    & python $probePath
                }

                if ($LASTEXITCODE -eq 0) {
                    return
                }

                if ($attempt -lt $Attempts) {
                    Write-Host "[DB] PostgreSQL healthcheck failed; retrying ($attempt/$Attempts)..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        $env:DATABASE_URL = $oldDatabaseUrlForProbe
        Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
    }

    throw "PostgreSQL healthcheck failed through 127.0.0.1 tunnel. Check the phone PostgreSQL service and SSH tunnel."
}

function Split-SshTarget {
    param([string]$Target)

    if ($Target -notmatch "^(?<user>[^@]+)@(?<host>.+)$") {
        throw "PHONE_SSH_TARGET must be in user@host form, for example: u0_a000@192.168.1.13"
    }
    return @{
        User = $Matches["user"]
        Host = $Matches["host"]
    }
}

function Start-ParamikoTunnel {
    param(
        [string]$PythonCommand,
        [string]$Target,
        [int]$TargetPort,
        [string]$Password,
        [int]$LocalPort,
        [string]$ForwardHost,
        [int]$ForwardPort
    )

    $targetParts = Split-SshTarget -Target $Target
    $helperPath = Join-Path ([System.IO.Path]::GetTempPath()) ("mavra-phone-tunnel-{0}.py" -f ([guid]::NewGuid().ToString("N")))
    $helper = @'
import os
import select
import socketserver
import sys
import threading
import time

import paramiko

ssh_host = os.environ["PHONE_SSH_HOST"]
ssh_port = int(os.environ["PHONE_SSH_PORT"])
ssh_user = os.environ["PHONE_SSH_USER"]
ssh_password = os.environ["PHONE_SSH_PASSWORD"]
local_host = "127.0.0.1"
local_port = int(os.environ["PHONE_LOCAL_DB_PORT"])
remote_host = os.environ["PHONE_REMOTE_DB_HOST"]
remote_port = int(os.environ["PHONE_REMOTE_DB_PORT"])

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(
    ssh_host,
    port=ssh_port,
    username=ssh_user,
    password=ssh_password,
    look_for_keys=False,
    allow_agent=False,
    timeout=10,
)
transport = client.get_transport()
transport.set_keepalive(30)

try:
    probe_channel = transport.open_channel(
        "direct-tcpip",
        (remote_host, remote_port),
        ("127.0.0.1", 0),
        timeout=5,
    )
    probe_channel.close()
except Exception as exc:
    print(
        f"remote PostgreSQL TCP port is not reachable at {remote_host}:{remote_port}: {type(exc).__name__}: {exc}",
        file=sys.stderr,
        flush=True,
    )
    client.close()
    raise SystemExit(2)


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        channel = transport.open_channel(
            "direct-tcpip",
            (remote_host, remote_port),
            self.request.getpeername(),
        )
        try:
            while True:
                readable, _, _ = select.select([self.request, channel], [], [])
                if self.request in readable:
                    data = self.request.recv(16384)
                    if not data:
                        break
                    channel.sendall(data)
                if channel in readable:
                    data = channel.recv(16384)
                    if not data:
                        break
                    self.request.sendall(data)
        finally:
            channel.close()


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


server = Server((local_host, local_port), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
print("tunnel-ready", flush=True)
try:
    while True:
        time.sleep(3600)
finally:
    server.shutdown()
    client.close()
'@
    Set-Content -LiteralPath $helperPath -Value $helper -Encoding UTF8

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $PythonCommand
    $startInfo.Arguments = "`"$helperPath`""
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.Environment["PHONE_SSH_HOST"] = $targetParts.Host
    $startInfo.Environment["PHONE_SSH_PORT"] = "$TargetPort"
    $startInfo.Environment["PHONE_SSH_USER"] = $targetParts.User
    $startInfo.Environment["PHONE_SSH_PASSWORD"] = $Password
    $startInfo.Environment["PHONE_LOCAL_DB_PORT"] = "$LocalPort"
    $startInfo.Environment["PHONE_REMOTE_DB_HOST"] = $ForwardHost
    $startInfo.Environment["PHONE_REMOTE_DB_PORT"] = "$ForwardPort"

    $process = [System.Diagnostics.Process]::Start($startInfo)
    Start-Sleep -Seconds 2
    Remove-Item -LiteralPath $helperPath -Force -ErrorAction SilentlyContinue
    if ($process.HasExited) {
        $stderr = $process.StandardError.ReadToEnd()
        if ($stderr) {
            throw "SSH tunnel failed: $stderr"
        }
        throw "SSH tunnel failed before it became ready."
    }
    return $process
}

if ([string]::IsNullOrWhiteSpace($SshTarget) -and -not $UseExistingTunnel) {
    throw "PHONE_SSH_TARGET is required, for example: `$env:PHONE_SSH_TARGET='u0_a000@192.168.1.13'"
}

if ($Concurrency -lt 1) {
    throw "Concurrency must be >= 1"
}

if ($Kind -notin @("all", "product", "job", "analysis")) {
    throw "Kind must be one of: all, product, job, analysis"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $projectRoot "backend"
$profileRoot = $projectRoot
$tunnelProcess = $null
$oldDatabaseUrl = $env:DATABASE_URL
$oldProfileRoot = $env:PRICE_MONITOR_PROFILE_ROOT

try {
    if (-not (Test-TcpPort -HostName "127.0.0.1" -Port $LocalDbPort)) {
        if ($UseExistingTunnel) {
            throw "No PostgreSQL tunnel is listening on 127.0.0.1:$LocalDbPort."
        }

        Write-Host "[Tunnel] Starting SSH tunnel on 127.0.0.1:$LocalDbPort -> ${RemoteDbHost}:$RemoteDbPort" -ForegroundColor Cyan
        $paramikoPython = Get-ParamikoPython
        if ($paramikoPython) {
            if ([string]::IsNullOrWhiteSpace($SshPassword)) {
                $secureSshPassword = Read-Host "SSH password for $SshTarget" -AsSecureString
                $SshPassword = ConvertTo-PlainText -SecureValue $secureSshPassword
            }
            $tunnelProcess = Start-ParamikoTunnel `
                -PythonCommand $paramikoPython `
                -Target $SshTarget `
                -TargetPort $SshPort `
                -Password $SshPassword `
                -LocalPort $LocalDbPort `
                -ForwardHost $RemoteDbHost `
                -ForwardPort $RemoteDbPort
        }
        else {
            $sshArgs = @(
                "-o", "ExitOnForwardFailure=yes",
                "-N",
                "-L", "127.0.0.1:${LocalDbPort}:${RemoteDbHost}:${RemoteDbPort}",
                "-p", "$SshPort",
                $SshTarget
            )
            Write-Host "[Tunnel] Python paramiko is not available; falling back to OpenSSH." -ForegroundColor Yellow
            $tunnelProcess = Start-Process ssh -ArgumentList $sshArgs -PassThru -WindowStyle Hidden
        }
        Start-Sleep -Seconds 2

        if (-not (Test-TcpPort -HostName "127.0.0.1" -Port $LocalDbPort)) {
            if ($tunnelProcess -and -not $tunnelProcess.HasExited) {
                Stop-Process -Id $tunnelProcess.Id -Force
            }
            $manualCommand = "ssh -o ExitOnForwardFailure=yes -N -L 127.0.0.1:${LocalDbPort}:${RemoteDbHost}:${RemoteDbPort} -p $SshPort $SshTarget"
            throw "SSH tunnel did not become ready. If the phone requires password auth, run this command in another PowerShell window first: $manualCommand"
        }
    }
    else {
        Write-Host "[Tunnel] Reusing existing listener on 127.0.0.1:$LocalDbPort" -ForegroundColor DarkGray
    }

    if ([string]::IsNullOrWhiteSpace($DatabaseUrl) -and -not [string]::IsNullOrWhiteSpace($DatabasePassword)) {
        $DatabaseUrl = New-DatabaseUrl `
            -User $DatabaseUser `
            -Password $DatabasePassword `
            -HostName "127.0.0.1" `
            -Port $LocalDbPort `
            -Database $DatabaseName
        $DatabasePassword = $null
    }

    if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
        $paramikoPython = Get-ParamikoPython
        if ($paramikoPython) {
            if ([string]::IsNullOrWhiteSpace($SshPassword)) {
                $secureSshPassword = Read-Host "SSH password for $SshTarget to read phone .env" -AsSecureString
                $SshPassword = ConvertTo-PlainText -SecureValue $secureSshPassword
            }

            Write-Host "[DB] Loading DATABASE_URL from phone .env under $RemoteProjectRoot" -ForegroundColor DarkGray
            $DatabaseUrl = Get-RemoteDatabaseUrlFromEnvFile `
                -PythonCommand $paramikoPython `
                -Target $SshTarget `
                -TargetPort $SshPort `
                -Password $SshPassword `
                -ProjectRoot $RemoteProjectRoot `
                -TunnelPort $LocalDbPort
        }
    }

    $SshPassword = $null

    if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
        Write-Host "[DB] Phone .env DATABASE_URL was not available; falling back to local .env." -ForegroundColor Yellow
        $DatabaseUrl = Get-LocalDatabaseUrlFromEnvFile -ProjectRoot $projectRoot -TunnelPort $LocalDbPort
    }

    if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
        $securePassword = Read-Host "PostgreSQL password for $DatabaseUser@$DatabaseName" -AsSecureString
        $plainPassword = ConvertTo-PlainText -SecureValue $securePassword
        try {
            $DatabaseUrl = New-DatabaseUrl `
                -User $DatabaseUser `
                -Password $plainPassword `
                -HostName "127.0.0.1" `
                -Port $LocalDbPort `
                -Database $DatabaseName
        }
        finally {
            $plainPassword = $null
        }
    }

    $env:DATABASE_URL = $DatabaseUrl
    $env:PRICE_MONITOR_PROFILE_ROOT = $profileRoot

    Write-Host "[Worker] DATABASE_URL is set for this process only." -ForegroundColor DarkGray
    Write-Host "[Worker] PRICE_MONITOR_PROFILE_ROOT=$profileRoot" -ForegroundColor DarkGray
    Write-Host "[DB] Checking PostgreSQL connectivity through tunnel..." -ForegroundColor Cyan
    try {
        Invoke-PostgresHealthcheck -BackendDir $backendDir -DatabaseUrl $DatabaseUrl
    }
    catch {
        if (-not [string]::IsNullOrWhiteSpace($env:PHONE_DATABASE_URL)) {
            throw
        }

        Write-Host "[DB] Existing DATABASE_URL did not authenticate. Please enter the phone PostgreSQL password." -ForegroundColor Yellow
        $securePassword = Read-Host "PostgreSQL password for $DatabaseUser@$DatabaseName" -AsSecureString
        $plainPassword = ConvertTo-PlainText -SecureValue $securePassword
        try {
            $DatabaseUrl = New-DatabaseUrl `
                -User $DatabaseUser `
                -Password $plainPassword `
                -HostName "127.0.0.1" `
                -Port $LocalDbPort `
                -Database $DatabaseName
            $env:DATABASE_URL = $DatabaseUrl
        }
        finally {
            $plainPassword = $null
        }
        Invoke-PostgresHealthcheck -BackendDir $backendDir -DatabaseUrl $DatabaseUrl
    }
    Write-Host "[Worker] Starting crawler worker: kind=$Kind concurrency=$Concurrency" -ForegroundColor Cyan

    Push-Location $backendDir
    try {
        $workerArgs = @("-m", "app.workers.crawler", "--kind", $Kind, "--concurrency", "$Concurrency")
        foreach ($item in $Platform) {
            if (-not [string]::IsNullOrWhiteSpace($item)) {
                $workerArgs += @("--platform", $item)
            }
        }
        if ($Once) {
            $workerArgs += "--once"
        }

        if (Get-Command uv -ErrorAction SilentlyContinue) {
            & uv run --extra dev python @workerArgs
        }
        elseif (Test-Path (Join-Path $backendDir ".venv/Scripts/python.exe")) {
            & (Join-Path $backendDir ".venv/Scripts/python.exe") @workerArgs
        }
        else {
            & python @workerArgs
        }
        exit $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:DATABASE_URL = $oldDatabaseUrl
    $env:PRICE_MONITOR_PROFILE_ROOT = $oldProfileRoot

    if ($tunnelProcess -and -not $tunnelProcess.HasExited) {
        Write-Host "[Tunnel] Stopping SSH tunnel process $($tunnelProcess.Id)" -ForegroundColor DarkGray
        Stop-Process -Id $tunnelProcess.Id -Force
    }
}
