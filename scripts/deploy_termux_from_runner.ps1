param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-RepoRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Invoke-ExternalCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string[]]$ArgumentList = @()
  )

  & $FilePath @ArgumentList
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($ArgumentList -join ' ')"
  }
}

function ConvertTo-BashSingleQuoted {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ($null -eq $Value) {
    $Value = ""
  }

  return "'" + $Value.Replace("'", "'\''") + "'"
}

function Copy-FileWithScp {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$RemoteTarget,

    [Parameter(Mandatory = $true)]
    [string[]]$ScpBaseArgs
  )

  Invoke-ExternalCommand -FilePath "scp" -ArgumentList ($ScpBaseArgs + @($SourcePath, $RemoteTarget))
}

function Get-FreeTcpPort {
  $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
  try {
    $listener.Start()
    return $listener.LocalEndpoint.Port
  } finally {
    $listener.Stop()
  }
}

function Get-LocalAddressForRemote {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RemoteHost,

    [Parameter(Mandatory = $true)]
    [int]$RemotePort
  )

  $socket = New-Object System.Net.Sockets.Socket(
    [System.Net.Sockets.AddressFamily]::InterNetwork,
    [System.Net.Sockets.SocketType]::Dgram,
    [System.Net.Sockets.ProtocolType]::Udp
  )
  try {
    $socket.Connect($RemoteHost, $RemotePort)
    return $socket.LocalEndPoint.Address.ToString()
  } finally {
    $socket.Dispose()
  }
}

function Get-PythonCommand {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python) {
    return [PSCustomObject]@{
      FilePath = $python.Source
      Args = @("-m", "http.server")
    }
  }

  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) {
    return [PSCustomObject]@{
      FilePath = $py.Source
      Args = @("-3", "-m", "http.server")
    }
  }

  return $null
}

function Wait-ForLocalHttpArtifact {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url
  )

  for ($attempt = 1; $attempt -le 20; $attempt++) {
    try {
      Invoke-WebRequest -UseBasicParsing -Method Head -Uri $Url -TimeoutSec 2 | Out-Null
      return
    } catch {
      Start-Sleep -Milliseconds 250
    }
  }

  throw "Timed out waiting for local artifact HTTP server: $Url"
}

function Start-ArtifactHttpServer {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RunnerTemp,

    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts
  )

  $python = Get-PythonCommand
  if (-not $python) {
    throw "Python was not found on the runner; cannot use HTTP artifact transfer."
  }

  $httpRoot = Join-Path $RunnerTemp ("mavra-termux-http-" + [guid]::NewGuid().ToString("N"))
  $tokenPath = [guid]::NewGuid().ToString("N")
  $tokenDir = Join-Path $httpRoot $tokenPath
  New-Item -ItemType Directory -Force -Path $tokenDir | Out-Null

  foreach ($name in $Artifacts.Keys) {
    Copy-Item -LiteralPath $Artifacts[$name] -Destination (Join-Path $tokenDir $name) -Force
  }

  $port = Get-FreeTcpPort
  $stdoutLog = Join-Path $httpRoot "http-server.out.log"
  $stderrLog = Join-Path $httpRoot "http-server.err.log"
  $argumentList = $python.Args + @($port.ToString(), "--bind", "0.0.0.0")

  $process = Start-Process `
    -FilePath $python.FilePath `
    -ArgumentList $argumentList `
    -WorkingDirectory $httpRoot `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -WindowStyle Hidden `
    -PassThru

  try {
    Wait-ForLocalHttpArtifact -Url "http://127.0.0.1:$port/$tokenPath/frontend-web.tar.gz"
  } catch {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    throw
  }

  return [PSCustomObject]@{
    Process = $process
    Root = $httpRoot
    Port = $port
    TokenPath = $tokenPath
  }
}

function Stop-ArtifactHttpServer {
  param(
    [AllowNull()]
    [object]$Server
  )

  if ($null -eq $Server) {
    return
  }

  if ($Server.Process -and -not $Server.Process.HasExited) {
    Stop-Process -Id $Server.Process.Id -Force -ErrorAction SilentlyContinue
  }

  if ($Server.Root) {
    Remove-Item -LiteralPath $Server.Root -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-RemoteTransferCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $true)]
    [string]$RemoteCommand
  )

  & "ssh" @($SshBase + @($Remote, $RemoteCommand))
  return $LASTEXITCODE
}

function Wait-ForRemoteHttpArtifact {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $false)]
    [int]$Attempts = 20
  )

  $testUrl = "$BaseUrl/frontend-web.tar.gz"
  $testCommand = "curl -fsSI --connect-timeout 2 --max-time 5 $(ConvertTo-BashSingleQuoted $testUrl) >/dev/null"

  for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    $exitCode = Invoke-RemoteTransferCommand -Remote $Remote -SshBase $SshBase -RemoteCommand $testCommand
    if ($exitCode -eq 0) {
      return
    }
    Start-Sleep -Milliseconds 500
  }

  throw "Timed out waiting for Termux to reach the artifact HTTP endpoint."
}

function Start-SshReverseTunnel {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Server,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase
  )

  for ($attempt = 1; $attempt -le 5; $attempt++) {
    $remotePort = Get-Random -Minimum 30000 -Maximum 60999
    $stdoutLog = Join-Path $Server.Root "ssh-tunnel-$remotePort.out.log"
    $stderrLog = Join-Path $Server.Root "ssh-tunnel-$remotePort.err.log"
    $forward = "127.0.0.1:${remotePort}:127.0.0.1:$($Server.Port)"
    $argumentList = $SshBase + @(
      "-N",
      "-o", "ExitOnForwardFailure=yes",
      "-R", $forward,
      $Remote
    )

    $process = Start-Process `
      -FilePath "ssh" `
      -ArgumentList $argumentList `
      -RedirectStandardOutput $stdoutLog `
      -RedirectStandardError $stderrLog `
      -WindowStyle Hidden `
      -PassThru

    Start-Sleep -Milliseconds 750
    if ($process.HasExited) {
      continue
    }

    $baseUrl = "http://127.0.0.1:$remotePort/$($Server.TokenPath)"
    try {
      Wait-ForRemoteHttpArtifact -BaseUrl $baseUrl -Remote $Remote -SshBase $SshBase -Attempts 10
      return [PSCustomObject]@{
        Process = $process
        RemotePort = $remotePort
        BaseUrl = $baseUrl
      }
    } catch {
      Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
  }

  throw "Could not establish an SSH reverse tunnel for artifact transfer."
}

function Stop-SshReverseTunnel {
  param(
    [AllowNull()]
    [object]$Tunnel
  )

  if ($null -eq $Tunnel) {
    return
  }

  if ($Tunnel.Process -and -not $Tunnel.Process.HasExited) {
    Stop-Process -Id $Tunnel.Process.Id -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-RemoteArtifactDownload {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts,

    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
  )

  $commands = @("set -euo pipefail", "mkdir -p $(ConvertTo-BashSingleQuoted $Incoming)")
  foreach ($name in $Artifacts.Keys) {
    $targetPath = "$Incoming/$name"
    $sourceUrl = "$BaseUrl/$name"
    $commands += "curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 5 -o $(ConvertTo-BashSingleQuoted $targetPath) $(ConvertTo-BashSingleQuoted $sourceUrl)"
  }

  $exitCode = Invoke-RemoteTransferCommand -Remote $Remote -SshBase $SshBase -RemoteCommand ($commands -join "; ")
  if ($exitCode -ne 0) {
    throw "Remote artifact download failed with exit code $exitCode."
  }

  return $true
}

function Copy-ArtifactsWithHttpPull {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts,

    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $true)]
    [string]$RunnerTemp,

    [Parameter(Mandatory = $false)]
    [ValidateSet("direct", "tunnel")]
    [string]$Mode = "direct"
  )

  $server = $null
  $tunnel = $null
  try {
    $server = Start-ArtifactHttpServer -RunnerTemp $RunnerTemp -Artifacts $Artifacts

    if ($Mode -eq "tunnel") {
      $tunnel = Start-SshReverseTunnel -Server $server -Remote $Remote -SshBase $SshBase
      Write-Host "[INFO] Serving deployment artifacts through SSH reverse tunnel on Termux 127.0.0.1:$($tunnel.RemotePort)."
      return Invoke-RemoteArtifactDownload -Artifacts $Artifacts -Incoming $Incoming -Remote $Remote -SshBase $SshBase -BaseUrl $tunnel.BaseUrl
    }

    $runnerAddress = Get-LocalAddressForRemote -RemoteHost $env:TERMUX_HOST -RemotePort ([int]$env:TERMUX_PORT)
    $baseUrl = "http://${runnerAddress}:$($server.Port)/$($server.TokenPath)"
    Write-Host "[INFO] Serving deployment artifacts from runner at http://${runnerAddress}:$($server.Port)/<token>/"
    return Invoke-RemoteArtifactDownload -Artifacts $Artifacts -Incoming $Incoming -Remote $Remote -SshBase $SshBase -BaseUrl $baseUrl
  } finally {
    Stop-SshReverseTunnel -Tunnel $tunnel
    Stop-ArtifactHttpServer -Server $server
  }
}

if ($DryRun) {
  Write-Host "[DryRun] Parsed deploy_termux_from_runner.ps1 successfully."
  exit 0
}

$required = @(
  "TERMUX_HOST",
  "TERMUX_PORT",
  "TERMUX_USER",
  "TERMUX_APP_DIR",
  "TERMUX_KNOWN_HOSTS",
  "TERMUX_SSH_KEY",
  "DEPLOY_SHA",
  "GITHUB_TOKEN",
  "GITHUB_REPOSITORY",
  "GITHUB_RUN_ID"
)

foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Missing required environment variable: $name"
  }
}

$repoRoot = Get-RepoRoot
$remoteScriptPath = Join-Path $repoRoot "scripts/deploy_termux_remote.sh"

$runnerTemp = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
  [System.IO.Path]::GetTempPath()
} else {
  $env:RUNNER_TEMP
}

$sshDir = Join-Path $runnerTemp "mavra-termux-ssh"
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
$keyPath = Join-Path $sshDir "deploy_key"
$knownHostsPath = Join-Path $sshDir "known_hosts"
$remoteScriptUploadPath = Join-Path $sshDir "deploy_termux_remote.sh"
$remoteEnvUploadPath = Join-Path $sshDir "deploy_env.sh"

[System.IO.File]::WriteAllText($keyPath, $env:TERMUX_SSH_KEY.Replace("`r", "") + "`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText($knownHostsPath, $env:TERMUX_KNOWN_HOSTS.Replace("`r", "") + "`n", [System.Text.Encoding]::ASCII)

try {
  Invoke-ExternalCommand -FilePath "icacls" -ArgumentList @($keyPath, "/inheritance:r", "/grant:r", "$($env:USERNAME):(R)")
} catch {
  Write-Warning "Could not tighten key ACL with icacls; continuing on self-hosted runner."
}

$remote = "$env:TERMUX_USER@$env:TERMUX_HOST"
$sshBase = @(
  "-i", $keyPath,
  "-p", $env:TERMUX_PORT,
  "-o", "BatchMode=yes",
  "-o", "IdentitiesOnly=yes",
  "-o", "UserKnownHostsFile=$knownHostsPath",
  "-o", "StrictHostKeyChecking=yes"
)
$scpBase = @(
  "-i", $keyPath,
  "-P", $env:TERMUX_PORT,
  "-o", "BatchMode=yes",
  "-o", "IdentitiesOnly=yes",
  "-o", "UserKnownHostsFile=$knownHostsPath",
  "-o", "StrictHostKeyChecking=yes"
)
$incoming = "$env:TERMUX_APP_DIR/.deploy/incoming/$env:DEPLOY_SHA"

try {
  foreach ($requiredPath in @($remoteScriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
      throw "Required deploy input missing: $requiredPath"
    }
  }

  $remoteScriptContent = [System.IO.File]::ReadAllText($remoteScriptPath).Replace("`r`n", "`n").Replace("`r", "`n").TrimStart([char]0xFEFF)
  [System.IO.File]::WriteAllText($remoteScriptUploadPath, $remoteScriptContent, (New-Object System.Text.UTF8Encoding($false)))

  $incomingQuoted = ConvertTo-BashSingleQuoted $incoming
  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "mkdir -p $incomingQuoted"))
  Copy-FileWithScp -SourcePath $remoteScriptUploadPath -RemoteTarget "${remote}:$incoming/deploy_termux_remote.sh" -ScpBaseArgs $scpBase

  if (-not [string]::IsNullOrWhiteSpace($env:TERMUX_ARTIFACT_DIR)) {
    $artifactRoot = (Resolve-Path -LiteralPath $env:TERMUX_ARTIFACT_DIR).Path
    $frontendArtifact = Join-Path (Join-Path $artifactRoot "frontend") "frontend-web.tar.gz"
    $blogStandaloneArtifact = Join-Path (Join-Path $artifactRoot "blog") "blog-standalone.tar.gz"
    $blogStaticArtifact = Join-Path (Join-Path $artifactRoot "blog") "blog-static.tar.gz"
    $blogPublicArtifact = Join-Path (Join-Path $artifactRoot "blog") "blog-public.tar.gz"

    foreach ($artifactPath in @($frontendArtifact, $blogStandaloneArtifact, $blogStaticArtifact)) {
      if (-not (Test-Path -LiteralPath $artifactPath)) {
        throw "Downloaded deploy artifact missing: $artifactPath"
      }
    }

    $artifacts = @{
      "frontend-web.tar.gz" = $frontendArtifact
      "blog-standalone.tar.gz" = $blogStandaloneArtifact
      "blog-static.tar.gz" = $blogStaticArtifact
    }
    if (Test-Path -LiteralPath $blogPublicArtifact) {
      $artifacts["blog-public.tar.gz"] = $blogPublicArtifact
    }

    $transferMode = if ([string]::IsNullOrWhiteSpace($env:TERMUX_TRANSFER_MODE)) {
      "auto"
    } else {
      $env:TERMUX_TRANSFER_MODE.Trim().ToLowerInvariant()
    }

    $transferred = $false
    if ($transferMode -eq "auto" -or $transferMode -eq "http") {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux over LAN via direct HTTP pull."
      try {
        $transferred = Copy-ArtifactsWithHttpPull -Artifacts $artifacts -Incoming $incoming -Remote $remote -SshBase $sshBase -RunnerTemp $runnerTemp -Mode "direct"
      } catch {
        if ($transferMode -eq "http") {
          throw
        }
        Write-Warning "Direct HTTP artifact transfer failed; trying SSH reverse tunnel. $($_.Exception.Message)"
      }
    }

    if (-not $transferred -and ($transferMode -eq "auto" -or $transferMode -eq "tunnel")) {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux via SSH reverse-tunnel HTTP pull."
      try {
        $transferred = Copy-ArtifactsWithHttpPull -Artifacts $artifacts -Incoming $incoming -Remote $remote -SshBase $sshBase -RunnerTemp $runnerTemp -Mode "tunnel"
      } catch {
        if ($transferMode -eq "tunnel") {
          throw
        }
        Write-Warning "SSH reverse-tunnel artifact transfer failed. $($_.Exception.Message)"
      }
    }

    if (-not $transferred -and $transferMode -eq "scp") {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux over LAN via scp."
      Copy-FileWithScp -SourcePath $frontendArtifact -RemoteTarget "${remote}:$incoming/frontend-web.tar.gz" -ScpBaseArgs $scpBase
      Copy-FileWithScp -SourcePath $blogStandaloneArtifact -RemoteTarget "${remote}:$incoming/blog-standalone.tar.gz" -ScpBaseArgs $scpBase
      Copy-FileWithScp -SourcePath $blogStaticArtifact -RemoteTarget "${remote}:$incoming/blog-static.tar.gz" -ScpBaseArgs $scpBase
      if (Test-Path -LiteralPath $blogPublicArtifact) {
        Copy-FileWithScp -SourcePath $blogPublicArtifact -RemoteTarget "${remote}:$incoming/blog-public.tar.gz" -ScpBaseArgs $scpBase
      }
    }

    if (-not $transferred -and $transferMode -ne "scp") {
      throw "Artifact transfer failed without using slow scp fallback. Set TERMUX_TRANSFER_MODE=scp to force legacy scp."
    }
  }

  $remoteEnvContent = @(
    "export PROJECT_ROOT_OVERRIDE=$(ConvertTo-BashSingleQuoted $env:TERMUX_APP_DIR)",
    "export GITHUB_TOKEN=$(ConvertTo-BashSingleQuoted $env:GITHUB_TOKEN)",
    "export GITHUB_REPOSITORY=$(ConvertTo-BashSingleQuoted $env:GITHUB_REPOSITORY)",
    "export GITHUB_RUN_ID=$(ConvertTo-BashSingleQuoted $env:GITHUB_RUN_ID)",
    "export FRONTEND_ARTIFACT_NAME='termux-frontend-web'",
    "export BLOG_ARTIFACT_NAME='termux-blog-build'"
  ) -join "`n"
  [System.IO.File]::WriteAllText($remoteEnvUploadPath, $remoteEnvContent + "`n", (New-Object System.Text.UTF8Encoding($false)))
  Copy-FileWithScp -SourcePath $remoteEnvUploadPath -RemoteTarget "${remote}:$incoming/deploy_env.sh" -ScpBaseArgs $scpBase

  $remoteEnvPath = "$incoming/deploy_env.sh"
  $remoteScriptPathOnHost = "$incoming/deploy_termux_remote.sh"
  $remoteCommand = "set -euo pipefail; chmod 600 $(ConvertTo-BashSingleQuoted $remoteEnvPath); . $(ConvertTo-BashSingleQuoted $remoteEnvPath); rm -f $(ConvertTo-BashSingleQuoted $remoteEnvPath); exec bash $(ConvertTo-BashSingleQuoted $remoteScriptPathOnHost) $(ConvertTo-BashSingleQuoted $env:DEPLOY_SHA)"
  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, $remoteCommand))
} finally {
  Remove-Item -LiteralPath $sshDir -Recurse -Force -ErrorAction SilentlyContinue
}
