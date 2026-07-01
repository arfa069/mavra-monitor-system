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

function ConvertTo-ProcessArgument {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ($null -eq $Value) {
    $Value = ""
  }

  if ($Value -eq "") {
    return '""'
  }

  if ($Value -notmatch '[\s"]') {
    return $Value
  }

  return '"' + (($Value -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}

function Join-ProcessArguments {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ArgumentList
  )

  return ($ArgumentList | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join " "
}

function Invoke-SshScript {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBaseArgs,

    [Parameter(Mandatory = $true)]
    [string]$Script
  )

  $normalizedScript = $Script.Replace("`r`n", "`n").Replace("`r", "`n")
  if (-not $normalizedScript.EndsWith("`n")) {
    $normalizedScript += "`n"
  }

  $processInfo = New-Object System.Diagnostics.ProcessStartInfo
  $processInfo.FileName = "ssh"
  $processInfo.Arguments = Join-ProcessArguments ($SshBaseArgs + @($Remote, "bash -s"))
  $processInfo.UseShellExecute = $false
  $processInfo.RedirectStandardInput = $true

  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $processInfo

  [void]$process.Start()
  $stdinBytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($normalizedScript)
  $process.StandardInput.BaseStream.Write($stdinBytes, 0, $stdinBytes.Length)
  $process.StandardInput.BaseStream.Flush()
  $process.StandardInput.Close()
  $process.WaitForExit()

  if ($process.ExitCode -ne 0) {
    throw "Remote SSH script failed with exit code $($process.ExitCode)"
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

  $remoteScriptContent = [System.IO.File]::ReadAllText($remoteScriptPath).Replace("`r`n", "`n").Replace("`r", "`n")
  [System.IO.File]::WriteAllText($remoteScriptUploadPath, $remoteScriptContent, (New-Object System.Text.UTF8Encoding($false)))

  $incomingQuoted = ConvertTo-BashSingleQuoted $incoming
  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "mkdir -p $incomingQuoted"))
  Copy-FileWithScp -SourcePath $remoteScriptUploadPath -RemoteTarget "${remote}:$incoming/deploy_termux_remote.sh" -ScpBaseArgs $scpBase

  $remoteScript = @"
set -euo pipefail
export PROJECT_ROOT_OVERRIDE=$(ConvertTo-BashSingleQuoted $env:TERMUX_APP_DIR)
export GITHUB_TOKEN=$(ConvertTo-BashSingleQuoted $env:GITHUB_TOKEN)
export GITHUB_REPOSITORY=$(ConvertTo-BashSingleQuoted $env:GITHUB_REPOSITORY)
export GITHUB_RUN_ID=$(ConvertTo-BashSingleQuoted $env:GITHUB_RUN_ID)
export FRONTEND_ARTIFACT_NAME='termux-frontend-web'
export BLOG_ARTIFACT_NAME='termux-blog-build'
exec bash $(ConvertTo-BashSingleQuoted "$incoming/deploy_termux_remote.sh") $(ConvertTo-BashSingleQuoted $env:DEPLOY_SHA)
"@

  Invoke-SshScript -Remote $remote -SshBaseArgs $sshBase -Script $remoteScript
} finally {
  Remove-Item -LiteralPath $sshDir -Recurse -Force -ErrorAction SilentlyContinue
}
