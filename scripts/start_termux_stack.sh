#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
BLOG_STANDALONE_DIR="$PROJECT_ROOT/blog-frontend/.next/standalone"
FRONTEND_BUILD_DIR="$PROJECT_ROOT/frontend/build/web"
DEPLOY_LOG_DIR="${DEPLOY_LOG_DIR:-$PROJECT_ROOT/.deploy/logs}"

shell_quote() {
  printf "%q" "$1"
}

ENV_FILE="${ENV_FILE:-}"
if [[ -z "$ENV_FILE" ]]; then
  for candidate in "$PROJECT_ROOT/.env" "$BACKEND_DIR/.env"; do
    if [[ -f "$candidate" ]]; then
      ENV_FILE="$candidate"
      break
    fi
  done
fi

ENV_SOURCE_PREFIX=""
if [[ -n "$ENV_FILE" && -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  if . "$ENV_FILE"; then
    echo "[OK] Loaded environment file: $ENV_FILE"
    ENV_SOURCE_PREFIX="set -a; . $(shell_quote "$ENV_FILE"); set +a; "
  else
    echo "[WARN] Could not source environment file: $ENV_FILE" >&2
  fi
  set +a
else
  echo "[WARN] No environment file found at $PROJECT_ROOT/.env or $BACKEND_DIR/.env" >&2
fi

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
  local log_file="$DEPLOY_LOG_DIR/$session_name.log"

  if tmux has-session -t "$session_name" >/dev/null 2>&1; then
    echo "[OK] tmux session already exists: $session_name"
    return
  fi

  mkdir -p "$DEPLOY_LOG_DIR"
  : > "$log_file"

  tmux new-session -d -s "$session_name" bash -lc "{ $command_line; } >> $(shell_quote "$log_file") 2>&1; status=\$?; echo \"[ERROR] $session_name exited with status \$status\" >> $(shell_quote "$log_file"); sleep 30; exit \$status"
  sleep 1
  if ! tmux has-session -t "$session_name" >/dev/null 2>&1; then
    echo "[ERROR] tmux session exited immediately: $session_name" >&2
    if [[ -f "$log_file" ]]; then
      tail -n 80 "$log_file" >&2 || true
    fi
    return 1
  fi

  echo "[OK] Started tmux session: $session_name"
}

nginx_process_running() {
  ps -ef | grep -Eq "[n]ginx"
}

tcp_ready() {
  python - "$1" "$2" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

try:
    with socket.create_connection((host, port), timeout=1):
        pass
except OSError:
    raise SystemExit(1)
PY
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
if tcp_ready "${REDIS_HOST:-127.0.0.1}" "${REDIS_PORT:-6379}"; then
  echo "[OK] Redis already reachable"
else
  start_session "$REDIS_SESSION" "redis-server"
fi

echo "[Start] PostgreSQL"
if tcp_ready "${POSTGRES_HOST:-127.0.0.1}" "${POSTGRES_PORT:-5432}"; then
  echo "[OK] PostgreSQL already reachable"
else
  start_session "$POSTGRES_SESSION" "mkdir -p $(shell_quote "$POSTGRES_DATA_DIR") && pg_ctl -D $(shell_quote "$POSTGRES_DATA_DIR") start -l $(shell_quote "$POSTGRES_LOG") && tail -f $(shell_quote "$POSTGRES_LOG")"
fi

sleep 2

echo "[Start] Backend"
start_session "$BACKEND_SESSION" "cd $(shell_quote "$BACKEND_DIR") && ${ENV_SOURCE_PREFIX}python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

echo "[Start] Blog"
start_session "$BLOG_SESSION" "cd $(shell_quote "$BLOG_STANDALONE_DIR") && ${ENV_SOURCE_PREFIX}env NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3001 BLOG_PUBLIC_BASE_URL=$(shell_quote "$BLOG_PUBLIC_BASE_URL") BLOG_API_BASE_URL=$(shell_quote "$BLOG_API_BASE_URL") BLOG_BACKEND_ORIGIN=$(shell_quote "$BLOG_BACKEND_ORIGIN") NEXT_PUBLIC_BLOG_BASE_URL=$(shell_quote "$BLOG_PUBLIC_BASE_URL") node server.js"

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
