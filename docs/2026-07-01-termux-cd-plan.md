# Termux CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add continuous deployment from GitHub Actions to the private Termux server at `192.168.1.13` without exposing the server to the public internet.

**Architecture:** The existing CI workflow remains the quality gate. After the six required checks pass on `main`, a Windows self-hosted runner builds Flutter Web and the Next.js blog, uploads the artifacts over SSH to Termux, and runs a remote deployment script that checks out the exact commit, backs up state, migrates the database, restarts services, reloads Nginx, and verifies health.

**Tech Stack:** GitHub Actions, Windows self-hosted runner, PowerShell, OpenSSH/SCP, Termux, tmux, PostgreSQL, Alembic, Flutter Web, Next.js standalone, Nginx.

---

## Decisions Locked

- Runner host: Windows self-hosted runner on the local network.
- Trigger: automatic deploy on `push` to `main`.
- Build location: Flutter Web and Blog both build on the Windows runner, then upload to Termux.
- Deployment target: `u0_a323@192.168.1.13:8022`, app directory `/data/data/com.termux/files/home/apps/mavra-monitor-system`.
- Public ingress remains `http://192.168.1.13:3000`.
- CD does not depend on Android or Windows smoke jobs and does not restore iOS CI.

## Task 1: Add the CI Deploy Job

**Files:**

- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Add write-safe deploy permissions and production environment**

Keep the workflow-level permission as `contents: read`. Add a new `deploy-termux` job after the existing quality-gate jobs.

The job must use:

```yaml
deploy-termux:
  name: Deploy Termux
  runs-on: [self-hosted, Windows, mavra-deploy]
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  needs:
    - lint
    - test
    - compile
    - api-contract
    - flutter-web-fast
    - blog
  environment: production-termux
  concurrency:
    group: production-termux
    cancel-in-progress: false
```

Expected: deploy waits for the same six checks required by branch protection.

- [ ] **Step 2: Wire the deploy script**

Add checkout and script execution steps:

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Deploy to Termux
    shell: pwsh
    env:
      TERMUX_HOST: ${{ vars.TERMUX_HOST }}
      TERMUX_PORT: ${{ vars.TERMUX_PORT }}
      TERMUX_USER: ${{ vars.TERMUX_USER }}
      TERMUX_APP_DIR: ${{ vars.TERMUX_APP_DIR }}
      TERMUX_KNOWN_HOSTS: ${{ vars.TERMUX_KNOWN_HOSTS }}
      TERMUX_SSH_KEY: ${{ secrets.TERMUX_SSH_KEY }}
      DEPLOY_SHA: ${{ github.sha }}
    run: ./scripts/deploy_termux_from_runner.ps1
```

Expected: no secret values are echoed by the workflow.

## Task 2: Create the Windows Runner Deploy Script

**Files:**

- Create: `scripts/deploy_termux_from_runner.ps1`

- [ ] **Step 1: Implement input validation and SSH material setup**

Create a PowerShell script with strict mode and these required environment variables:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

$sshDir = Join-Path $env:RUNNER_TEMP "mavra-termux-ssh"
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
$keyPath = Join-Path $sshDir "deploy_key"
$knownHostsPath = Join-Path $sshDir "known_hosts"

[System.IO.File]::WriteAllText($keyPath, $env:TERMUX_SSH_KEY.Replace("`r", "") + "`n", [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText($knownHostsPath, $env:TERMUX_KNOWN_HOSTS.Replace("`r", "") + "`n", [System.Text.Encoding]::ASCII)

try {
  & icacls $keyPath /inheritance:r /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {
  Write-Warning "Could not tighten key ACL with icacls; continuing on self-hosted runner."
}
```

Expected: SSH key is written only to `$RUNNER_TEMP`, and the script never prints key contents.

- [ ] **Step 2: Build Flutter Web**

Add:

```powershell
Push-Location frontend
try {
  flutter pub get
  flutter build web --dart-define=API_BASE_URL=/api/v1
} finally {
  Pop-Location
}
```

Expected: `frontend/build/web/index.html` exists.

- [ ] **Step 3: Build Blog on Windows runner**

Add:

```powershell
Push-Location blog-frontend
try {
  $env:BLOG_PUBLIC_BASE_URL = "http://192.168.1.13:3000"
  $env:BLOG_API_BASE_URL = "http://127.0.0.1:8000/api/v1"
  $env:BLOG_BACKEND_ORIGIN = "http://127.0.0.1:8000"
  $env:NEXT_PUBLIC_BLOG_BASE_URL = "http://192.168.1.13:3000"
  npm ci
  npm run build
} finally {
  Pop-Location
}
```

Expected: `blog-frontend/.next/standalone/server.js` and `blog-frontend/.next/static` exist.

- [ ] **Step 4: Upload artifacts to an incoming release directory**

Use OpenSSH/SCP with fixed known hosts:

```powershell
$remote = "$env:TERMUX_USER@$env:TERMUX_HOST"
$sshBase = @(
  "-i", $keyPath,
  "-p", $env:TERMUX_PORT,
  "-o", "UserKnownHostsFile=$knownHostsPath",
  "-o", "StrictHostKeyChecking=yes"
)
$scpBase = @(
  "-i", $keyPath,
  "-P", $env:TERMUX_PORT,
  "-o", "UserKnownHostsFile=$knownHostsPath",
  "-o", "StrictHostKeyChecking=yes"
)
$incoming = "$env:TERMUX_APP_DIR/.deploy/incoming/$env:DEPLOY_SHA"

ssh @sshBase $remote "mkdir -p '$incoming/frontend' '$incoming/blog-standalone' '$incoming/blog-static'"
scp @scpBase -r "frontend/build/web/*" "${remote}:$incoming/frontend/"
scp @scpBase -r "blog-frontend/.next/standalone/*" "${remote}:$incoming/blog-standalone/"
scp @scpBase -r "blog-frontend/.next/static" "${remote}:$incoming/blog-static/"
if (Test-Path "blog-frontend/public") {
  scp @scpBase -r "blog-frontend/public" "${remote}:$incoming/public"
}
```

Expected: all artifacts are uploaded under `.deploy/incoming/<sha>` and no production directory is replaced yet.

- [ ] **Step 5: Run the remote deploy script and clean up local SSH files**

Add:

```powershell
try {
  ssh @sshBase $remote "cd '$env:TERMUX_APP_DIR' && bash scripts/deploy_termux_remote.sh '$env:DEPLOY_SHA'"
} finally {
  Remove-Item -LiteralPath $sshDir -Recurse -Force -ErrorAction SilentlyContinue
}
```

Expected: deployment finishes or fails with a clear remote error; key files are removed.

## Task 3: Create the Termux Remote Deploy Script

**Files:**

- Create: `scripts/deploy_termux_remote.sh`

- [ ] **Step 1: Add strict shell setup and commit argument validation**

Create:

```bash
#!/usr/bin/env bash

set -euo pipefail

DEPLOY_SHA="${1:-}"
if [[ -z "$DEPLOY_SHA" ]]; then
  echo "[ERROR] Missing deploy sha" >&2
  exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

INCOMING_DIR="$PROJECT_ROOT/.deploy/incoming/$DEPLOY_SHA"
BACKUP_ROOT="$PROJECT_ROOT/.deploy/backups/$(date +%Y%m%d-%H%M%S)-$DEPLOY_SHA"
FRONTEND_DIR="$PROJECT_ROOT/frontend/build/web"
BLOG_STANDALONE_DIR="$PROJECT_ROOT/blog-frontend/.next/standalone"
BLOG_STATIC_DIR="$PROJECT_ROOT/blog-frontend/.next/static"
BLOG_PUBLIC_DIR="$PROJECT_ROOT/blog-frontend/public"
```

Expected: script exits if no SHA is supplied.

- [ ] **Step 2: Fail on dirty remote repo**

Add:

```bash
if [[ -n "$(git status --porcelain)" ]]; then
  echo "[ERROR] Remote worktree has uncommitted changes:" >&2
  git status --short >&2
  exit 3
fi
```

Expected: remote local edits are never overwritten by CD.

- [ ] **Step 3: Checkout the exact commit**

Add:

```bash
git fetch origin main
git checkout "$DEPLOY_SHA"
```

Expected: remote code matches the GitHub Actions commit exactly.

- [ ] **Step 4: Verify uploaded artifacts before touching production paths**

Add:

```bash
test -f "$INCOMING_DIR/frontend/index.html"
test -f "$INCOMING_DIR/blog-standalone/server.js"
test -d "$INCOMING_DIR/blog-static/static"
```

Expected: missing upload fails before backup or replacement.

- [ ] **Step 5: Back up database and current artifacts**

Add:

```bash
mkdir -p "$BACKUP_ROOT"

if command -v pg_dump >/dev/null 2>&1; then
  pg_dump "${DATABASE_URL:-}" > "$BACKUP_ROOT/database.sql" || echo "[WARN] pg_dump failed; continuing only if DATABASE_URL is not suitable for pg_dump" >&2
fi

if [[ -d "$FRONTEND_DIR" ]]; then
  mkdir -p "$BACKUP_ROOT/frontend"
  cp -a "$FRONTEND_DIR/." "$BACKUP_ROOT/frontend/"
fi

if [[ -d "$BLOG_STANDALONE_DIR" ]]; then
  mkdir -p "$BACKUP_ROOT/blog-standalone"
  cp -a "$BLOG_STANDALONE_DIR/." "$BACKUP_ROOT/blog-standalone/"
fi

if [[ -d "$BLOG_STATIC_DIR" ]]; then
  mkdir -p "$BACKUP_ROOT/blog-static"
  cp -a "$BLOG_STATIC_DIR/." "$BACKUP_ROOT/blog-static/"
fi

if [[ -d "$BLOG_PUBLIC_DIR" ]]; then
  mkdir -p "$BACKUP_ROOT/blog-public"
  cp -a "$BLOG_PUBLIC_DIR/." "$BACKUP_ROOT/blog-public/"
fi
```

Expected: static artifacts are recoverable if health checks fail.

- [ ] **Step 6: Replace artifacts from incoming directory**

Add:

```bash
rm -rf "$FRONTEND_DIR" "$BLOG_STANDALONE_DIR" "$BLOG_STATIC_DIR"
mkdir -p "$FRONTEND_DIR" "$BLOG_STANDALONE_DIR" "$BLOG_STATIC_DIR"
cp -a "$INCOMING_DIR/frontend/." "$FRONTEND_DIR/"
cp -a "$INCOMING_DIR/blog-standalone/." "$BLOG_STANDALONE_DIR/"
cp -a "$INCOMING_DIR/blog-static/static" "$BLOG_STATIC_DIR"

if [[ -d "$INCOMING_DIR/public" ]]; then
  rm -rf "$BLOG_PUBLIC_DIR"
  mkdir -p "$BLOG_PUBLIC_DIR"
  cp -a "$INCOMING_DIR/public/." "$BLOG_PUBLIC_DIR/"
fi
```

Expected: production artifact paths contain only the uploaded build output.

- [ ] **Step 7: Run database migration**

Add:

```bash
cd "$PROJECT_ROOT/backend"
python -m alembic upgrade head
cd "$PROJECT_ROOT"
```

Expected: migration completes before services are restarted.

- [ ] **Step 8: Restart app sessions and run startup script**

Add:

```bash
tmux kill-session -t mavra-backend 2>/dev/null || true
tmux kill-session -t mavra-blog 2>/dev/null || true
bash scripts/start_termux_stack.sh
```

Expected: backend and blog run the new commit and new artifacts.

- [ ] **Step 9: Health check and static rollback**

Add:

```bash
restore_static_artifacts() {
  echo "[WARN] Restoring previous static artifacts from $BACKUP_ROOT" >&2
  if [[ -d "$BACKUP_ROOT/frontend" ]]; then
    rm -rf "$FRONTEND_DIR"
    mkdir -p "$FRONTEND_DIR"
    cp -a "$BACKUP_ROOT/frontend/." "$FRONTEND_DIR/"
  fi
  if [[ -d "$BACKUP_ROOT/blog-standalone" ]]; then
    rm -rf "$BLOG_STANDALONE_DIR"
    mkdir -p "$BLOG_STANDALONE_DIR"
    cp -a "$BACKUP_ROOT/blog-standalone/." "$BLOG_STANDALONE_DIR/"
  fi
  if [[ -d "$BACKUP_ROOT/blog-static" ]]; then
    rm -rf "$BLOG_STATIC_DIR"
    mkdir -p "$BLOG_STATIC_DIR"
    cp -a "$BACKUP_ROOT/blog-static/." "$BLOG_STATIC_DIR/"
  fi
  if [[ -d "$BACKUP_ROOT/blog-public" ]]; then
    rm -rf "$BLOG_PUBLIC_DIR"
    mkdir -p "$BLOG_PUBLIC_DIR"
    cp -a "$BACKUP_ROOT/blog-public/." "$BLOG_PUBLIC_DIR/"
  fi
  tmux kill-session -t mavra-blog 2>/dev/null || true
  bash scripts/start_termux_stack.sh
}

if ! curl -fsS http://127.0.0.1:8000/health >/dev/null; then
  restore_static_artifacts
  exit 4
fi

if ! curl -fsSI http://127.0.0.1:3000/ >/dev/null; then
  restore_static_artifacts
  exit 5
fi

if ! curl -fsSI http://127.0.0.1:3000/blog >/dev/null; then
  restore_static_artifacts
  exit 6
fi

nginx -t
tmux ls
echo "[OK] Deployed $DEPLOY_SHA"
```

Expected: failed health checks restore previous static frontend/blog artifacts. Database rollback is manual from the `pg_dump` backup.

## Task 4: Document Setup and Operations

**Files:**

- Modify: `doc/deployment-progress.md`
- Create or modify: `doc/howto-termux-cd.md`

- [ ] **Step 1: Record required GitHub configuration**

Document:

```text
Environment: production-termux
Runner labels: self-hosted, Windows, mavra-deploy
Variables:
  TERMUX_HOST=192.168.1.13
  TERMUX_PORT=8022
  TERMUX_USER=u0_a323
  TERMUX_APP_DIR=/data/data/com.termux/files/home/apps/mavra-monitor-system
  TERMUX_KNOWN_HOSTS=<ssh-keyscan result for 192.168.1.13:8022>
Secrets:
  TERMUX_SSH_KEY=<deployment private key>
```

Expected: a future maintainer can configure the environment without reading chat history.

- [ ] **Step 2: Record rollback behavior**

Document:

```text
If health checks fail after artifact replacement, the deploy script restores previous Flutter Web and Blog static artifacts. Database migrations are not automatically downgraded. Use the timestamped pg_dump under .deploy/backups for manual recovery if needed.
```

Expected: rollback boundary is explicit.

## Task 5: Verification and Commit

**Files:**

- Verify: `.github/workflows/ci.yml`
- Verify: `scripts/deploy_termux_from_runner.ps1`
- Verify: `scripts/deploy_termux_remote.sh`
- Verify: `doc/deployment-progress.md`
- Verify: `doc/howto-termux-cd.md`

- [ ] **Step 1: Run static checks**

Run:

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy_termux_from_runner.ps1 -DryRun
bash -n scripts/deploy_termux_remote.sh
```

Expected: all commands exit 0. If `bash` is unavailable on Windows, run the bash syntax check on WSL or Termux.

- [ ] **Step 2: Verify workflow shape**

Run:

```powershell
rg -n "deploy-termux|production-termux|mavra-deploy|TERMUX_SSH_KEY|concurrency|cancel-in-progress" .github/workflows/ci.yml
```

Expected: deploy job is present, uses the production environment, and has serial deployment concurrency.

- [ ] **Step 3: Commit the CD implementation**

Run:

```powershell
git add .github/workflows/ci.yml scripts/deploy_termux_from_runner.ps1 scripts/deploy_termux_remote.sh doc/deployment-progress.md doc/howto-termux-cd.md
git commit -m "Add Termux CD deployment workflow"
```

Expected: one focused commit containing only CD workflow, scripts, and deployment docs.

## Acceptance Criteria

- A push to `main` starts `deploy-termux` only after the six required CI checks pass.
- The deploy job runs on the Windows self-hosted runner with label `mavra-deploy`.
- Flutter Web and Blog are built on the Windows runner and uploaded to Termux.
- Termux deploy refuses to overwrite dirty remote repo state.
- Termux deploy backs up database and existing static artifacts before replacement.
- Termux deploy restarts backend/blog and validates backend health, frontend root, blog root, Nginx config, and tmux sessions.
- CI logs do not reveal SSH keys, `.env`, tokens, cookies, or database passwords.
