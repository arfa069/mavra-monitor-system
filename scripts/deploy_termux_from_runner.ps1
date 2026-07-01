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
  "DEPLOY_SHA"
)

foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Missing required environment variable: $name"
  }
}

$repoRoot = Get-RepoRoot
$artifactDir = Join-Path $repoRoot "deploy-artifacts"
$frontendArchive = Join-Path $artifactDir "frontend-web.tar.gz"
$blogStandaloneArchive = Join-Path $artifactDir "blog-standalone.tar.gz"
$blogStaticArchive = Join-Path $artifactDir "blog-static.tar.gz"
$blogPublicArchive = Join-Path $artifactDir "blog-public.tar.gz"
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
  foreach ($requiredPath in @($frontendArchive, $blogStandaloneArchive, $blogStaticArchive, $remoteScriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
      throw "Required deploy input missing: $requiredPath"
    }
  }

  $remoteScriptContent = [System.IO.File]::ReadAllText($remoteScriptPath).Replace("`r`n", "`n").Replace("`r", "`n")
  [System.IO.File]::WriteAllText($remoteScriptUploadPath, $remoteScriptContent, (New-Object System.Text.UTF8Encoding($false)))

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "mkdir -p '$incoming'"))
  Copy-FileWithScp -SourcePath $frontendArchive -RemoteTarget "${remote}:$incoming/frontend-web.tar.gz" -ScpBaseArgs $scpBase
  Copy-FileWithScp -SourcePath $blogStandaloneArchive -RemoteTarget "${remote}:$incoming/blog-standalone.tar.gz" -ScpBaseArgs $scpBase
  Copy-FileWithScp -SourcePath $blogStaticArchive -RemoteTarget "${remote}:$incoming/blog-static.tar.gz" -ScpBaseArgs $scpBase
  Copy-FileWithScp -SourcePath $remoteScriptUploadPath -RemoteTarget "${remote}:$incoming/deploy_termux_remote.sh" -ScpBaseArgs $scpBase

  if (Test-Path -LiteralPath $blogPublicArchive) {
    Copy-FileWithScp -SourcePath $blogPublicArchive -RemoteTarget "${remote}:$incoming/blog-public.tar.gz" -ScpBaseArgs $scpBase
  }

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "PROJECT_ROOT_OVERRIDE='$env:TERMUX_APP_DIR' bash '$incoming/deploy_termux_remote.sh' '$env:DEPLOY_SHA'"))
} finally {
  Remove-Item -LiteralPath $sshDir -Recurse -Force -ErrorAction SilentlyContinue
}
