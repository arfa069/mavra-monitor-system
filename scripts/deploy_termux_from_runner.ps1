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

function Copy-DirectoryContentsWithScp {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,

    [Parameter(Mandatory = $true)]
    [string]$RemoteTarget,

    [Parameter(Mandatory = $true)]
    [string[]]$ScpBaseArgs
  )

  $items = Get-ChildItem -LiteralPath $SourceDirectory -Force
  foreach ($item in $items) {
    Invoke-ExternalCommand -FilePath "scp" -ArgumentList ($ScpBaseArgs + @("-r", $item.FullName, $RemoteTarget))
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
  "DEPLOY_SHA"
)

foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Missing required environment variable: $name"
  }
}

$repoRoot = Get-RepoRoot
$frontendDir = Join-Path $repoRoot "frontend"
$blogDir = Join-Path $repoRoot "blog-frontend"
$frontendBuildDir = Join-Path $frontendDir "build/web"
$blogStandaloneDir = Join-Path $blogDir ".next/standalone"
$blogStaticDir = Join-Path $blogDir ".next/static"
$blogPublicDir = Join-Path $blogDir "public"

$runnerTemp = if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
  [System.IO.Path]::GetTempPath()
} else {
  $env:RUNNER_TEMP
}

$sshDir = Join-Path $runnerTemp "mavra-termux-ssh"
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
$keyPath = Join-Path $sshDir "deploy_key"
$knownHostsPath = Join-Path $sshDir "known_hosts"

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
  Push-Location $frontendDir
  try {
    Invoke-ExternalCommand -FilePath "flutter" -ArgumentList @("pub", "get")
    Invoke-ExternalCommand -FilePath "flutter" -ArgumentList @("build", "web", "--dart-define=API_BASE_URL=/api/v1")
  } finally {
    Pop-Location
  }

  if (-not (Test-Path (Join-Path $frontendBuildDir "index.html"))) {
    throw "Flutter web build output missing: $(Join-Path $frontendBuildDir 'index.html')"
  }

  Push-Location $blogDir
  try {
    $env:BLOG_PUBLIC_BASE_URL = "http://192.168.1.13:3000"
    $env:BLOG_API_BASE_URL = "http://127.0.0.1:8000/api/v1"
    $env:BLOG_BACKEND_ORIGIN = "http://127.0.0.1:8000"
    $env:NEXT_PUBLIC_BLOG_BASE_URL = "http://192.168.1.13:3000"
    Invoke-ExternalCommand -FilePath "npm" -ArgumentList @("ci")
    Invoke-ExternalCommand -FilePath "npm" -ArgumentList @("run", "build")
  } finally {
    Pop-Location
  }

  if (-not (Test-Path (Join-Path $blogStandaloneDir "server.js"))) {
    throw "Blog standalone build output missing: $(Join-Path $blogStandaloneDir 'server.js')"
  }
  if (-not (Test-Path $blogStaticDir)) {
    throw "Blog static build output missing: $blogStaticDir"
  }

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "mkdir -p '$incoming/frontend' '$incoming/blog-standalone' '$incoming/blog-static'"))
  Copy-DirectoryContentsWithScp -SourceDirectory $frontendBuildDir -RemoteTarget "${remote}:$incoming/frontend/" -ScpBaseArgs $scpBase
  Copy-DirectoryContentsWithScp -SourceDirectory $blogStandaloneDir -RemoteTarget "${remote}:$incoming/blog-standalone/" -ScpBaseArgs $scpBase
  Invoke-ExternalCommand -FilePath "scp" -ArgumentList ($scpBase + @("-r", $blogStaticDir, "${remote}:$incoming/blog-static/"))

  if (Test-Path $blogPublicDir) {
    Invoke-ExternalCommand -FilePath "scp" -ArgumentList ($scpBase + @("-r", $blogPublicDir, "${remote}:$incoming/"))
  }

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($sshBase + @($remote, "cd '$env:TERMUX_APP_DIR' && bash scripts/deploy_termux_remote.sh '$env:DEPLOY_SHA'"))
} finally {
  Remove-Item -LiteralPath $sshDir -Recurse -Force -ErrorAction SilentlyContinue
}
