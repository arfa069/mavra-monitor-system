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

function Invoke-GitCapture {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ArgumentList
  )

  $output = & "git" @ArgumentList
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: git $($ArgumentList -join ' ')"
  }

  return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Get-RemoteCurrentSha {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $true)]
    [string]$AppDir
  )

  $remoteCommand = "cd $(ConvertTo-BashSingleQuoted $AppDir) && git rev-parse HEAD 2>/dev/null || true"
  $output = & "ssh" @($SshBase + @($Remote, $remoteCommand))
  if ($LASTEXITCODE -ne 0) {
    return ""
  }

  return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function New-DeploySourceBundle {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string]$DeploySha,

    [Parameter(Mandatory = $false)]
    [string]$RemoteCurrentSha = "",

    [Parameter(Mandatory = $true)]
    [string]$BundlePath
  )

  $currentHead = Invoke-GitCapture -ArgumentList @("-C", $RepoRoot, "rev-parse", "HEAD")
  if ($currentHead -ne $DeploySha) {
    throw "Local checkout HEAD ($currentHead) does not match DEPLOY_SHA ($DeploySha)."
  }

  if ($RemoteCurrentSha -eq $DeploySha) {
    Write-Host "[INFO] Remote source already at $DeploySha; skipping source bundle upload."
    return $false
  }

  $bundleArgs = @("-C", $RepoRoot, "bundle", "create", $BundlePath, "HEAD")
  if ($RemoteCurrentSha -match "^[0-9a-f]{40}$") {
    & "git" @("-C", $RepoRoot, "merge-base", "--is-ancestor", $RemoteCurrentSha, $DeploySha) *> $null
    if ($LASTEXITCODE -eq 0) {
      $bundleArgs += "^$RemoteCurrentSha"
      Write-Host "[INFO] Creating incremental source bundle from $($RemoteCurrentSha.Substring(0, 8)) to $($DeploySha.Substring(0, 8))."
    } else {
      Write-Host "[INFO] Remote SHA is not an ancestor of DEPLOY_SHA; creating full source bundle."
    }
  } else {
    Write-Host "[INFO] Remote SHA unavailable; creating full source bundle."
  }

  Invoke-ExternalCommand -FilePath "git" -ArgumentList $bundleArgs
  return $true
}

function Get-ArtifactHashes {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts
  )

  $hashes = @{}
  foreach ($name in $Artifacts.Keys) {
    $hashes[$name] = (Get-FileHash -Algorithm SHA256 -LiteralPath $Artifacts[$name]).Hash.ToLowerInvariant()
  }

  return $hashes
}

function Get-ArtifactCacheKeys {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts,

    [Parameter(Mandatory = $true)]
    [hashtable]$ArtifactHashes,

    [AllowEmptyString()]
    [string]$InputManifestPath
  )

  $cacheKeys = @{}
  foreach ($name in $Artifacts.Keys) {
    $cacheKeys[$name] = $ArtifactHashes[$name]
  }

  if ([string]::IsNullOrWhiteSpace($InputManifestPath)) {
    return $cacheKeys
  }

  if (-not (Test-Path -LiteralPath $InputManifestPath)) {
    Write-Warning "Artifact input hash manifest not found; falling back to content hash cache keys: $InputManifestPath"
    return $cacheKeys
  }

  foreach ($line in Get-Content -LiteralPath $InputManifestPath) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $trimmed -split "\s+", 3
    if ($parts.Count -lt 2) {
      Write-Warning "Ignoring malformed artifact input hash line: $trimmed"
      continue
    }

    $inputHash = $parts[0].ToLowerInvariant()
    $name = $parts[1]
    if (-not $Artifacts.ContainsKey($name)) {
      continue
    }

    if ($inputHash -notmatch "^[0-9a-f]{64}$") {
      Write-Warning "Ignoring invalid artifact input hash for $name."
      continue
    }

    $cacheKeys[$name] = $inputHash
  }

  return $cacheKeys
}

function Write-ArtifactCacheKeyManifest {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$ArtifactCacheKeys,

    [Parameter(Mandatory = $true)]
    [string]$ManifestPath
  )

  $lines = @()
  foreach ($name in ($ArtifactCacheKeys.Keys | Sort-Object)) {
    $lines += "$($ArtifactCacheKeys[$name])  $name"
  }

  [System.IO.File]::WriteAllText($ManifestPath, (($lines -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
}

function Restore-RemoteCachedArtifacts {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$CacheRoot,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase
  )

  $remoteManifest = "$Incoming/artifact-cache-keys.txt"
  $remoteCommand = @(
    "set -euo pipefail",
    "incoming=$(ConvertTo-BashSingleQuoted $Incoming)",
    "cache_root=$(ConvertTo-BashSingleQuoted $CacheRoot)",
    "manifest=$(ConvertTo-BashSingleQuoted $remoteManifest)",
    'if ! command -v sha256sum >/dev/null 2>&1; then echo "[WARN] sha256sum missing; artifact cache reuse disabled" >&2; exit 0; fi',
    'mkdir -p "$incoming" "$cache_root"',
    'while read -r cache_key name extra; do',
    '  cache_key="${cache_key%$''\r''}"',
    '  name="${name%$''\r''}"',
    '  [ -n "$cache_key" ] || continue',
    '  case "$cache_key" in *[!0123456789abcdef]*) echo "[WARN] Unsafe artifact cache key in manifest: $cache_key" >&2; continue ;; esac',
    '  case "$name" in frontend-web.tar.gz|blog-standalone.tar.gz|blog-static.tar.gz|blog-public.tar.gz) ;; *) echo "[WARN] Unsafe artifact name in manifest: $name" >&2; continue ;; esac',
    '  cache="$cache_root/$cache_key/$name"',
    '  cache_sha="$cache.sha256"',
    '  target="$incoming/$name"',
    '  if [ -f "$cache" ]; then',
    '    verified=0',
    '    if [ -f "$cache_sha" ] && (cd "$(dirname "$cache")" && sha256sum -c "$(basename "$cache_sha")" >/dev/null 2>&1); then',
    '      verified=1',
    '    else',
    '      actual_hash="$(sha256sum "$cache")"',
    '      actual_hash="${actual_hash%% *}"',
    '      if [ "$actual_hash" = "$cache_key" ]; then verified=1; fi',
    '    fi',
    '    if [ "$verified" -eq 1 ]; then',
    '      cp "$cache" "$target"',
    '      printf "%s\n" "$name"',
    '      continue',
    '    fi',
    '  fi',
    '  incoming_root="$(dirname "$incoming")"',
    '  for candidate in "$incoming_root"/*/"$name"; do',
    '    [ -f "$candidate" ] || continue',
    '    actual_hash="$(sha256sum "$candidate")"',
    '    actual_hash="${actual_hash%% *}"',
    '    if [ "$actual_hash" = "$cache_key" ]; then',
    '      mkdir -p "$(dirname "$cache")"',
    '      cp "$candidate" "$cache"',
    '      (cd "$(dirname "$cache")" && printf "%s  %s\n" "$actual_hash" "$name" > "$name.sha256")',
    '      cp "$cache" "$target"',
    '      printf "%s\n" "$name"',
    '      break',
    '    fi',
    '  done',
    'done < "$manifest"'
  ) -join "`n"

  $output = & "ssh" @($SshBase + @($Remote, $remoteCommand))
  if ($LASTEXITCODE -ne 0) {
    throw "Remote artifact cache restore failed with exit code $LASTEXITCODE."
  }

  return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Write-RemoteArtifactContentManifest {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase
  )

  $remoteCacheKeyManifest = "$Incoming/artifact-cache-keys.txt"
  $remoteContentManifest = "$Incoming/artifact-sha256.txt"
  $remoteCommand = @(
    "set -euo pipefail",
    "incoming=$(ConvertTo-BashSingleQuoted $Incoming)",
    "cache_manifest=$(ConvertTo-BashSingleQuoted $remoteCacheKeyManifest)",
    "content_manifest=$(ConvertTo-BashSingleQuoted $remoteContentManifest)",
    'if ! command -v sha256sum >/dev/null 2>&1; then echo "[ERROR] sha256sum missing; cannot verify deploy artifacts" >&2; exit 1; fi',
    'tmp="$content_manifest.tmp"',
    ': > "$tmp"',
    'while read -r cache_key name extra; do',
    '  cache_key="${cache_key%$''\r''}"',
    '  name="${name%$''\r''}"',
    '  [ -n "$cache_key" ] || continue',
    '  case "$name" in frontend-web.tar.gz|blog-standalone.tar.gz|blog-static.tar.gz|blog-public.tar.gz) ;; *) echo "[ERROR] Unsafe artifact name in cache manifest: $name" >&2; exit 2 ;; esac',
    '  target="$incoming/$name"',
    '  [ -f "$target" ] || { echo "[ERROR] Missing deploy artifact before content manifest: $target" >&2; exit 3; }',
    '  actual_hash="$(sha256sum "$target")"',
    '  actual_hash="${actual_hash%% *}"',
    '  printf "%s  %s\n" "$actual_hash" "$name" >> "$tmp"',
    'done < "$cache_manifest"',
    'mv "$tmp" "$content_manifest"'
  ) -join "`n"

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($SshBase + @($Remote, $remoteCommand))
}

function Select-ArtifactsForUpload {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Artifacts,

    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [string[]]$ReusedArtifactNames
  )

  $reused = @{}
  foreach ($name in $ReusedArtifactNames) {
    $reused[$name] = $true
  }

  $pending = @{}
  foreach ($name in $Artifacts.Keys) {
    if ($reused.ContainsKey($name)) {
      Write-Host "[INFO] Reusing cached Termux artifact: $name"
    } else {
      $pending[$name] = $Artifacts[$name]
    }
  }

  return $pending
}

function Update-RemoteArtifactCache {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$CacheRoot,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase
  )

  $remoteManifest = "$Incoming/artifact-cache-keys.txt"
  $remoteCommand = @(
    "set -euo pipefail",
    "incoming=$(ConvertTo-BashSingleQuoted $Incoming)",
    "cache_root=$(ConvertTo-BashSingleQuoted $CacheRoot)",
    "manifest=$(ConvertTo-BashSingleQuoted $remoteManifest)",
    'if ! command -v sha256sum >/dev/null 2>&1; then echo "[WARN] sha256sum missing; artifact cache update disabled" >&2; exit 0; fi',
    'mkdir -p "$cache_root"',
    'while read -r cache_key name extra; do',
    '  cache_key="${cache_key%$''\r''}"',
    '  name="${name%$''\r''}"',
    '  [ -n "$cache_key" ] || continue',
    '  case "$cache_key" in *[!0123456789abcdef]*) echo "[ERROR] Unsafe artifact cache key in manifest: $cache_key" >&2; exit 2 ;; esac',
    '  case "$name" in frontend-web.tar.gz|blog-standalone.tar.gz|blog-static.tar.gz|blog-public.tar.gz) ;; *) echo "[ERROR] Unsafe artifact name in manifest: $name" >&2; exit 2 ;; esac',
    '  target="$incoming/$name"',
    '  [ -f "$target" ] || { echo "[ERROR] Missing deploy artifact after transfer/cache restore: $target" >&2; exit 3; }',
    '  cache="$cache_root/$cache_key/$name"',
    '  cache_sha="$cache.sha256"',
    '  cache_valid=0',
    '  if [ -f "$cache" ]; then',
    '    if [ -f "$cache_sha" ] && (cd "$(dirname "$cache")" && sha256sum -c "$(basename "$cache_sha")" >/dev/null 2>&1); then',
    '      cache_valid=1',
    '    else',
    '      cache_actual_hash="$(sha256sum "$cache")"',
    '      cache_actual_hash="${cache_actual_hash%% *}"',
    '      if [ "$cache_actual_hash" = "$cache_key" ]; then cache_valid=1; fi',
    '    fi',
    '  fi',
    '  if [ "$cache_valid" -ne 1 ]; then',
    '    mkdir -p "$(dirname "$cache")"',
    '    cp "$target" "$cache"',
    '  fi',
    '  cache_actual_hash="$(sha256sum "$cache")"',
    '  cache_actual_hash="${cache_actual_hash%% *}"',
    '  (cd "$(dirname "$cache")" && printf "%s  %s\n" "$cache_actual_hash" "$name" > "$name.sha256")',
    'done < "$manifest"'
  ) -join "`n"

  Invoke-ExternalCommand -FilePath "ssh" -ArgumentList ($SshBase + @($Remote, $remoteCommand))
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

function Get-ArtifactReceiverScript {
  return @'
import argparse
import http.server
import os
import sys
import time
import urllib.parse


ALLOWED_FILES = {
    "frontend-web.tar.gz",
    "blog-standalone.tar.gz",
    "blog-static.tar.gz",
    "blog-public.tar.gz",
}


class ArtifactHandler(http.server.BaseHTTPRequestHandler):
    server_version = "MavraArtifactReceiver/1.0"

    def log_message(self, format, *args):
        # Avoid logging token-bearing request paths.
        sys.stderr.write("%s - request handled\n" % self.log_date_time_string())

    def _mark_request(self):
        self.server.last_request_at = time.monotonic()

    def _send_plain(self, status, body):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(encoded)

    def _path_parts(self):
        parsed = urllib.parse.urlparse(self.path)
        return [
            urllib.parse.unquote(part)
            for part in parsed.path.split("/")
            if part
        ]

    def _authorized_path(self):
        parts = self._path_parts()
        if len(parts) != 2 or parts[0] != self.server.token:
            return None

        filename = parts[1]
        if filename not in ALLOWED_FILES:
            return None

        return os.path.join(self.server.target_dir, filename)

    def do_GET(self):
        self._mark_request()
        if self.path == "/%s/health" % self.server.token:
            self._send_plain(200, "ok\n")
            return
        self._send_plain(404, "not found\n")

    def do_HEAD(self):
        self.do_GET()

    def do_PUT(self):
        self._mark_request()
        target_path = self._authorized_path()
        if target_path is None:
            self._send_plain(404, "not found\n")
            return

        length_header = self.headers.get("Content-Length")
        if not length_header:
            self._send_plain(411, "missing content length\n")
            return

        try:
            remaining = int(length_header)
        except ValueError:
            self._send_plain(400, "invalid content length\n")
            return

        os.makedirs(self.server.target_dir, exist_ok=True)
        tmp_path = target_path + ".part"
        with open(tmp_path, "wb") as handle:
            while remaining:
                chunk = self.rfile.read(min(1024 * 1024, remaining))
                if not chunk:
                    raise ConnectionError("client disconnected")
                handle.write(chunk)
                self._mark_request()
                remaining -= len(chunk)

        os.replace(tmp_path, target_path)
        self._send_plain(200, "stored\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--token", required=True)
    parser.add_argument("--directory", required=True)
    parser.add_argument("--idle-timeout", type=float, default=120.0)
    parser.add_argument("--max-lifetime", type=float, default=900.0)
    args = parser.parse_args()

    server = http.server.ThreadingHTTPServer((args.host, args.port), ArtifactHandler)
    server.token = args.token
    server.target_dir = args.directory
    server.last_request_at = time.monotonic()
    server.timeout = 1.0

    started_at = time.monotonic()
    while time.monotonic() - started_at < args.max_lifetime:
        server.handle_request()
        if time.monotonic() - server.last_request_at > args.idle_timeout:
            break


if __name__ == "__main__":
    main()
'@
}

function Wait-ForArtifactReceiver {
  param(
    [Parameter(Mandatory = $true)]
    [string]$HealthUrl,

    [Parameter(Mandatory = $false)]
    [int]$Attempts = 30
  )

  for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    & curl.exe -fsS --connect-timeout 2 --max-time 5 $HealthUrl *> $null
    if ($LASTEXITCODE -eq 0) {
      return
    }

    Start-Sleep -Milliseconds 500
  }

  throw "Timed out waiting for the Termux artifact receiver."
}

function Invoke-ArtifactReceiverUpload {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$FileName,

    [Parameter(Mandatory = $true)]
    [string]$UploadUrl
  )

  & curl.exe `
    -fS `
    --retry 3 `
    --retry-delay 2 `
    --connect-timeout 5 `
    --max-time 1800 `
    --upload-file $SourcePath `
    $UploadUrl

  if ($LASTEXITCODE -ne 0) {
    throw "Artifact receiver upload failed for ${FileName} with curl exit code $LASTEXITCODE."
  }
}

function Start-RemoteArtifactReceiver {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Incoming,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase,

    [Parameter(Mandatory = $true)]
    [string[]]$ScpBase,

    [Parameter(Mandatory = $true)]
    [string]$RunnerTemp
  )

  $localScriptPath = Join-Path $RunnerTemp ("mavra-artifact-receiver-" + [guid]::NewGuid().ToString("N") + ".py")
  $remoteScriptPath = "$Incoming/artifact_receiver.py"
  [System.IO.File]::WriteAllText($localScriptPath, (Get-ArtifactReceiverScript), (New-Object System.Text.UTF8Encoding($false)))
  Copy-FileWithScp -SourcePath $localScriptPath -RemoteTarget "${Remote}:$remoteScriptPath" -ScpBaseArgs $ScpBase

  for ($attempt = 1; $attempt -le 5; $attempt++) {
    $port = Get-Random -Minimum 30000 -Maximum 60999
    $token = [guid]::NewGuid().ToString("N")
    $remoteLogPath = "$Incoming/artifact_receiver.log"
    $remoteCommand = @(
      "set -euo pipefail",
      "mkdir -p $(ConvertTo-BashSingleQuoted $Incoming)",
      "nohup python $(ConvertTo-BashSingleQuoted $remoteScriptPath) --host 0.0.0.0 --port $port --token $(ConvertTo-BashSingleQuoted $token) --directory $(ConvertTo-BashSingleQuoted $Incoming) --idle-timeout 120 --max-lifetime 3600 > $(ConvertTo-BashSingleQuoted $remoteLogPath) 2>&1 < /dev/null & echo `$!"
    ) -join "; "

    $pidOutput = & "ssh" @($SshBase + @($Remote, $remoteCommand))
    if ($LASTEXITCODE -ne 0) {
      continue
    }

    $receiverProcessId = ($pidOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1)
    $baseUrl = "http://$($env:TERMUX_HOST):$port/$token"
    try {
      Wait-ForArtifactReceiver -HealthUrl "$baseUrl/health"
      return [PSCustomObject]@{
        Port = $port
        Token = $token
        BaseUrl = $baseUrl
        Pid = $receiverProcessId
        LocalScriptPath = $localScriptPath
        RemoteScriptPath = $remoteScriptPath
      }
    } catch {
      if ($receiverProcessId) {
        & "ssh" @($SshBase + @($Remote, "kill $receiverProcessId 2>/dev/null || true")) *> $null
      }
    }
  }

  Remove-Item -LiteralPath $localScriptPath -Force -ErrorAction SilentlyContinue
  throw "Could not start a reachable Termux artifact receiver."
}

function Stop-RemoteArtifactReceiver {
  param(
    [AllowNull()]
    [object]$Receiver,

    [Parameter(Mandatory = $true)]
    [string]$Remote,

    [Parameter(Mandatory = $true)]
    [string[]]$SshBase
  )

  if ($null -eq $Receiver) {
    return
  }

  if ($Receiver.Pid) {
    & "ssh" @($SshBase + @($Remote, "kill $($Receiver.Pid) 2>/dev/null || true; rm -f $(ConvertTo-BashSingleQuoted $($Receiver.RemoteScriptPath))")) *> $null
  }

  if ($Receiver.LocalScriptPath) {
    Remove-Item -LiteralPath $Receiver.LocalScriptPath -Force -ErrorAction SilentlyContinue
  }
}

function Copy-ArtifactsWithTermuxReceiver {
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
    [string[]]$ScpBase,

    [Parameter(Mandatory = $true)]
    [string]$RunnerTemp
  )

  $receiver = $null
  try {
    $receiver = Start-RemoteArtifactReceiver -Incoming $Incoming -Remote $Remote -SshBase $SshBase -ScpBase $ScpBase -RunnerTemp $RunnerTemp
    Write-Host "[INFO] Termux artifact receiver is listening on $($env:TERMUX_HOST):$($receiver.Port)."

    foreach ($name in $Artifacts.Keys) {
      Invoke-ArtifactReceiverUpload -SourcePath $Artifacts[$name] -FileName $name -UploadUrl "$($receiver.BaseUrl)/$name"
    }

    return $true
  } finally {
    Stop-RemoteArtifactReceiver -Receiver $receiver -Remote $Remote -SshBase $SshBase
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

$sshDir = Join-Path $runnerTemp ("mavra-termux-ssh-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
$keyPath = Join-Path $sshDir "deploy_key"
$knownHostsPath = Join-Path $sshDir "known_hosts"
$remoteScriptUploadPath = Join-Path $sshDir "deploy_termux_remote.sh"
$remoteEnvUploadPath = Join-Path $sshDir "deploy_env.sh"
$sourceBundlePath = Join-Path $sshDir "source.bundle"
$artifactCacheKeyManifestPath = Join-Path $sshDir "artifact-cache-keys.txt"

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

  $remoteCurrentSha = Get-RemoteCurrentSha -Remote $remote -SshBase $sshBase -AppDir $env:TERMUX_APP_DIR
  if (New-DeploySourceBundle -RepoRoot $repoRoot -DeploySha $env:DEPLOY_SHA -RemoteCurrentSha $remoteCurrentSha -BundlePath $sourceBundlePath) {
    Copy-FileWithScp -SourcePath $sourceBundlePath -RemoteTarget "${remote}:$incoming/source.bundle" -ScpBaseArgs $scpBase
  }

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

    $artifactHashes = Get-ArtifactHashes -Artifacts $artifacts
    $artifactInputManifestPath = if ([string]::IsNullOrWhiteSpace($env:TERMUX_ARTIFACT_INPUT_MANIFEST)) {
      ""
    } else {
      $env:TERMUX_ARTIFACT_INPUT_MANIFEST
    }
    $artifactCacheKeys = Get-ArtifactCacheKeys -Artifacts $artifacts -ArtifactHashes $artifactHashes -InputManifestPath $artifactInputManifestPath
    Write-ArtifactCacheKeyManifest -ArtifactCacheKeys $artifactCacheKeys -ManifestPath $artifactCacheKeyManifestPath
    Copy-FileWithScp -SourcePath $artifactCacheKeyManifestPath -RemoteTarget "${remote}:$incoming/artifact-cache-keys.txt" -ScpBaseArgs $scpBase

    $artifactCacheRoot = "$env:TERMUX_APP_DIR/.deploy/artifact-cache"
    $reusedArtifactNames = @(Restore-RemoteCachedArtifacts -Incoming $incoming -CacheRoot $artifactCacheRoot -Remote $remote -SshBase $sshBase)
    $artifactsToTransfer = Select-ArtifactsForUpload -Artifacts $artifacts -ReusedArtifactNames $reusedArtifactNames

    $transferMode = if ([string]::IsNullOrWhiteSpace($env:TERMUX_TRANSFER_MODE)) {
      "auto"
    } else {
      $env:TERMUX_TRANSFER_MODE.Trim().ToLowerInvariant()
    }

    $transferred = $false
    $validTransferModes = @("auto", "receiver", "direct", "http", "tunnel", "scp")
    if ($validTransferModes -notcontains $transferMode) {
      throw "Unsupported TERMUX_TRANSFER_MODE: $transferMode"
    }

    $transferred = $false
    if ($artifactsToTransfer.Count -eq 0) {
      Write-Host "[INFO] All deploy artifacts are already present in the Termux artifact cache; skipping artifact upload."
      $transferred = $true
    }

    if (-not $transferred -and ($transferMode -eq "auto" -or $transferMode -eq "receiver")) {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux via temporary Termux HTTP receiver."
      $transferred = Copy-ArtifactsWithTermuxReceiver -Artifacts $artifactsToTransfer -Incoming $incoming -Remote $remote -SshBase $sshBase -ScpBase $scpBase -RunnerTemp $runnerTemp
    }

    if (-not $transferred -and ($transferMode -eq "direct" -or $transferMode -eq "http")) {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux over LAN via direct HTTP pull."
      $transferred = Copy-ArtifactsWithHttpPull -Artifacts $artifactsToTransfer -Incoming $incoming -Remote $remote -SshBase $sshBase -RunnerTemp $runnerTemp -Mode "direct"
    }

    if (-not $transferred -and $transferMode -eq "tunnel") {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux via SSH reverse-tunnel HTTP pull."
      $transferred = Copy-ArtifactsWithHttpPull -Artifacts $artifactsToTransfer -Incoming $incoming -Remote $remote -SshBase $sshBase -RunnerTemp $runnerTemp -Mode "tunnel"
    }

    if (-not $transferred -and $transferMode -eq "scp") {
      Write-Host "[INFO] Uploading GitHub-built artifacts to Termux over LAN via scp."
      foreach ($name in $artifactsToTransfer.Keys) {
        Copy-FileWithScp -SourcePath $artifactsToTransfer[$name] -RemoteTarget "${remote}:$incoming/$name" -ScpBaseArgs $scpBase
      }
      $transferred = $true
    }

    if (-not $transferred -and $transferMode -ne "scp") {
      throw "Artifact transfer failed. Set TERMUX_TRANSFER_MODE=scp to force legacy scp."
    }

    Write-RemoteArtifactContentManifest -Incoming $incoming -Remote $remote -SshBase $sshBase
    Update-RemoteArtifactCache -Incoming $incoming -CacheRoot $artifactCacheRoot -Remote $remote -SshBase $sshBase
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
