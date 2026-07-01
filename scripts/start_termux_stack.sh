#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
BLOG_STANDALONE_DIR="$PROJECT_ROOT/blog-frontend/.next/standalone"
FRONTEND_BUILD_DIR="$PROJECT_ROOT/frontend/build/web"

REDIS_SESSION="${REDIS_SESSION:-redis}"
POSTGRES_SESSION="${POSTGRES_SESSION:-postgresql}"
BACKEND_SESSION="${BACKEND_SESSION:-mavra-backend}"
BLOG_SESSION="${BLOG_SESSION:-mavra-blog}"
POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-${PREFIX:-/data/data/com.termux/files/home}/var/lib/postgresql}"
POSTGRES_LOG="${POSTGRES_LOG:-$POSTGRES_DATA_DIR/logfile}"
BLOG_PUBLIC_BASE_URL="${BLOG_PUBLIC_BASE_URL:-http://192.168.1.13:3000}"
BLOG_API_BASE_URL="${BLOG_API_BASE_URL:-http://127.0.0.1:8000/api/v1}"
BLOG_BACKEND_ORIGIN="${BLOG_BACKEND_ORIGIN:-http://127.0.0.1:8000}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: $1" >&2
    exit 1
  fi
}

start_session() {
  local session_name="$1"
  local command_line="$2"

  if tmux has-session -t "$session_name" >/dev/null 2>&1; then
    echo "[OK] tmux session already exists: $session_name"
    return
  fi

  tmux new-session -d -s "$session_name" bash -lc "$command_line"
  echo "[OK] Started tmux session: $session_name"
}

nginx_process_running() {
  ps -ef | grep -Eq "[n]ginx"
}

require_cmd tmux
require_cmd nginx
require_cmd redis-server
require_cmd pg_ctl
require_cmd python
require_cmd node

if [[ ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
  echo "[ERROR] Flutter Web build not found: $FRONTEND_BUILD_DIR/index.html" >&2
  echo "Run on Windows first:" >&2
  echo "  cd frontend && flutter build web --dart-define=API_BASE_URL=/api/v1" >&2
  exit 1
fi

if [[ ! -f "$BLOG_STANDALONE_DIR/server.js" ]]; then
  echo "[ERROR] Blog standalone build not found: $BLOG_STANDALONE_DIR/server.js" >&2
  echo "Run on Windows first:" >&2
  echo "  cd blog-frontend && npm run build" >&2
  exit 1
fi

echo "[Start] Redis"
start_session "$REDIS_SESSION" "exec redis-server"

echo "[Start] PostgreSQL"
start_session "$POSTGRES_SESSION" "mkdir -p '$POSTGRES_DATA_DIR' && pg_ctl -D '$POSTGRES_DATA_DIR' start -l '$POSTGRES_LOG' && exec tail -f '$POSTGRES_LOG'"

sleep 2

echo "[Start] Backend"
start_session "$BACKEND_SESSION" "cd '$BACKEND_DIR' && exec python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

echo "[Start] Blog"
start_session "$BLOG_SESSION" "cd '$BLOG_STANDALONE_DIR' && exec env NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3001 BLOG_PUBLIC_BASE_URL='$BLOG_PUBLIC_BASE_URL' BLOG_API_BASE_URL='$BLOG_API_BASE_URL' BLOG_BACKEND_ORIGIN='$BLOG_BACKEND_ORIGIN' NEXT_PUBLIC_BLOG_BASE_URL='$BLOG_PUBLIC_BASE_URL' node server.js"

echo "[Start] Nginx"
if nginx -t >/dev/null 2>&1; then
  if nginx -s reload >/dev/null 2>&1; then
    echo "[OK] Reloaded Nginx"
  elif nginx_process_running; then
    echo "[OK] Nginx already running"
  else
    nginx
  fi
else
  nginx -t
  exit 1
fi

echo
echo "[OK] Services started or already running."
tmux ls || true
echo
echo "Flutter web is served by Nginx at: http://192.168.1.13:3000"
echo "Blog is served through the same入口 at: http://192.168.1.13:3000/blog"
echo "Backend API is proxied at: http://192.168.1.13:3000/api/v1"
