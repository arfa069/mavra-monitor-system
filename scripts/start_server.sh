#!/usr/bin/env bash
# Start backend, optional crawler worker, Flutter Web, and public blog frontend.

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_EXE="${PYTHON_EXE:-python}"
FRONTEND_PORT="${FRONTEND_PORT:-3000}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8000/api/v1}"
FRONTEND_BUILD_DIR="$PROJECT_ROOT/frontend/build/web"

if [[ "${BACKEND_ONLY:-0}" != "1" && "${FLUTTER_DEV:-0}" != "1" && ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
  echo "Flutter Web build not found: $FRONTEND_BUILD_DIR/index.html" >&2
  echo "Run: cd frontend && flutter build web --dart-define=API_BASE_URL=$API_BASE_URL" >&2
  echo "Or set FLUTTER_DEV=1 to run the Flutter dev server." >&2
  exit 1
fi

cleanup() {
  kill "${BACKEND_PID:-}" "${WORKER_PID:-}" "${FRONTEND_PID:-}" "${BLOG_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Starting backend on http://localhost:8000 ..."
(cd "$PROJECT_ROOT/backend" && "$PYTHON_EXE" -m uvicorn app.main:app --host 0.0.0.0 --port 8000) &
BACKEND_PID=$!

if [[ "${NO_CRAWLER_WORKER:-0}" != "1" ]]; then
  echo "Starting crawler worker ..."
  (cd "$PROJECT_ROOT/backend" && "$PYTHON_EXE" -m app.workers.crawler --kind all --concurrency "${CRAWLER_CONCURRENCY:-3}") &
  WORKER_PID=$!
fi

if [[ "${BACKEND_ONLY:-0}" != "1" ]]; then
  if [[ "${FLUTTER_DEV:-0}" == "1" ]]; then
    echo "Starting Flutter dev server on http://localhost:$FRONTEND_PORT ..."
    (cd "$PROJECT_ROOT/frontend" && flutter run -d chrome --web-port "$FRONTEND_PORT" --dart-define=API_BASE_URL="$API_BASE_URL") &
  else
    if [[ ! -f "$FRONTEND_BUILD_DIR/index.html" ]]; then
      echo "Flutter Web build not found: $FRONTEND_BUILD_DIR/index.html" >&2
      echo "Run: cd frontend && flutter build web --dart-define=API_BASE_URL=$API_BASE_URL" >&2
      echo "Or set FLUTTER_DEV=1 to run the Flutter dev server." >&2
      exit 1
    fi
    echo "Serving Flutter Web build on http://localhost:$FRONTEND_PORT ..."
    (cd "$PROJECT_ROOT/frontend" && "$PYTHON_EXE" -m http.server "$FRONTEND_PORT" --bind 127.0.0.1 --directory "$FRONTEND_BUILD_DIR") &
  fi
  FRONTEND_PID=$!

  if [[ "${NO_BLOG_FRONTEND:-0}" != "1" && -d "$PROJECT_ROOT/blog-frontend" ]]; then
    echo "Starting public blog on http://localhost:3001/blog ..."
    (cd "$PROJECT_ROOT/blog-frontend" && npm run dev -- --port 3001) &
    BLOG_PID=$!
  fi
fi

wait
