#!/usr/bin/env bash

set -euo pipefail

DEPLOY_SHA="${1:-}"
if [[ -z "$DEPLOY_SHA" ]]; then
  echo "[ERROR] Missing deploy sha" >&2
  exit 2
fi

PROJECT_ROOT="${PROJECT_ROOT_OVERRIDE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$PROJECT_ROOT"

INCOMING_DIR="$PROJECT_ROOT/.deploy/incoming/$DEPLOY_SHA"
BACKUP_ROOT="$PROJECT_ROOT/.deploy/backups/$(date +%Y%m%d-%H%M%S)-$DEPLOY_SHA"
EXTRACT_DIR="$INCOMING_DIR/extracted"
FRONTEND_DIR="$PROJECT_ROOT/frontend/build/web"
BLOG_STANDALONE_DIR="$PROJECT_ROOT/blog-frontend/.next/standalone"
BLOG_STATIC_DIR="$PROJECT_ROOT/blog-frontend/.next/static"
BLOG_PUBLIC_DIR="$PROJECT_ROOT/blog-frontend/public"
RESTORE_NEEDED=0
RESTORE_COMPLETED=0

restore_static_artifacts() {
  if [[ "$RESTORE_COMPLETED" -eq 1 ]]; then
    return
  fi

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
  elif [[ -d "$BLOG_PUBLIC_DIR" ]]; then
    rm -rf "$BLOG_PUBLIC_DIR"
  fi

  tmux kill-session -t mavra-backend 2>/dev/null || true
  tmux kill-session -t mavra-blog 2>/dev/null || true
  bash scripts/start_termux_stack.sh

  RESTORE_COMPLETED=1
}

handle_error() {
  local exit_code=$?
  if [[ "$RESTORE_NEEDED" -eq 1 ]]; then
    restore_static_artifacts || true
  fi
  exit "$exit_code"
}

trap handle_error ERR

if [[ -n "$(git status --porcelain)" ]]; then
  echo "[ERROR] Remote worktree has uncommitted changes:" >&2
  git status --short >&2
  exit 3
fi

git fetch origin main
git checkout "$DEPLOY_SHA"

test -f "$INCOMING_DIR/frontend-web.tar.gz"
test -f "$INCOMING_DIR/blog-standalone.tar.gz"
test -f "$INCOMING_DIR/blog-static.tar.gz"

rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR/frontend" "$EXTRACT_DIR/blog-standalone" "$EXTRACT_DIR/blog-static"
tar -xzf "$INCOMING_DIR/frontend-web.tar.gz" -C "$EXTRACT_DIR/frontend"
tar -xzf "$INCOMING_DIR/blog-standalone.tar.gz" -C "$EXTRACT_DIR/blog-standalone"
tar -xzf "$INCOMING_DIR/blog-static.tar.gz" -C "$EXTRACT_DIR/blog-static"

if [[ -f "$INCOMING_DIR/blog-public.tar.gz" ]]; then
  mkdir -p "$EXTRACT_DIR/public"
  tar -xzf "$INCOMING_DIR/blog-public.tar.gz" -C "$EXTRACT_DIR/public"
fi

test -f "$EXTRACT_DIR/frontend/index.html"
test -f "$EXTRACT_DIR/blog-standalone/server.js"
test -d "$EXTRACT_DIR/blog-static/static"

mkdir -p "$BACKUP_ROOT"

if command -v pg_dump >/dev/null 2>&1 && [[ -n "${DATABASE_URL:-}" ]]; then
  PG_DUMP_DATABASE_URL="${DATABASE_URL/+asyncpg/}"
  pg_dump "$PG_DUMP_DATABASE_URL" > "$BACKUP_ROOT/database.sql" || echo "[WARN] pg_dump failed; continuing only if DATABASE_URL is not suitable for pg_dump" >&2
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

RESTORE_NEEDED=1

rm -rf "$FRONTEND_DIR" "$BLOG_STANDALONE_DIR" "$BLOG_STATIC_DIR"
mkdir -p "$FRONTEND_DIR" "$BLOG_STANDALONE_DIR" "$BLOG_STATIC_DIR"
cp -a "$EXTRACT_DIR/frontend/." "$FRONTEND_DIR/"
cp -a "$EXTRACT_DIR/blog-standalone/." "$BLOG_STANDALONE_DIR/"
cp -a "$EXTRACT_DIR/blog-static/static" "$BLOG_STATIC_DIR"

if [[ -d "$EXTRACT_DIR/public" ]]; then
  rm -rf "$BLOG_PUBLIC_DIR"
  mkdir -p "$BLOG_PUBLIC_DIR"
  cp -a "$EXTRACT_DIR/public/." "$BLOG_PUBLIC_DIR/"
fi

cd "$PROJECT_ROOT/backend"
python -m alembic upgrade head
cd "$PROJECT_ROOT"

tmux kill-session -t mavra-backend 2>/dev/null || true
tmux kill-session -t mavra-blog 2>/dev/null || true
bash scripts/start_termux_stack.sh

if ! curl -fsS http://127.0.0.1:8000/health >/dev/null; then
  echo "[ERROR] Backend health check failed after deploy" >&2
  restore_static_artifacts
  exit 4
fi

if ! curl -fsSI http://127.0.0.1:3000/ >/dev/null; then
  echo "[ERROR] Frontend root health check failed after deploy" >&2
  restore_static_artifacts
  exit 5
fi

if ! curl -fsSI http://127.0.0.1:3000/blog >/dev/null; then
  echo "[ERROR] Blog health check failed after deploy" >&2
  restore_static_artifacts
  exit 6
fi

nginx -t
tmux ls
RESTORE_NEEDED=0
echo "[OK] Deployed $DEPLOY_SHA"
