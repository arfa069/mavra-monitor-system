#!/usr/bin/env bash
# Start backend, optional crawler worker, Vite console, and public blog frontend.

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_EXE="${PYTHON_EXE:-python}"

echo "Starting backend on http://localhost:8000 ..."
(cd "$PROJECT_ROOT/backend" && "$PYTHON_EXE" -m uvicorn app.main:app --host 0.0.0.0 --port 8000) &
BACKEND_PID=$!

if [[ "${NO_CRAWLER_WORKER:-0}" != "1" ]]; then
  echo "Starting crawler worker ..."
  (cd "$PROJECT_ROOT/backend" && "$PYTHON_EXE" -m app.workers.crawler --kind all --concurrency "${CRAWLER_CONCURRENCY:-3}") &
  WORKER_PID=$!
fi

if [[ "${BACKEND_ONLY:-0}" != "1" ]]; then
  echo "Starting Vite console on http://localhost:3000 ..."
  (cd "$PROJECT_ROOT/frontend" && npm run dev) &
  FRONTEND_PID=$!

  if [[ "${NO_BLOG_FRONTEND:-0}" != "1" && -d "$PROJECT_ROOT/blog-frontend" ]]; then
    echo "Starting public blog on http://localhost:3001/blog ..."
    (cd "$PROJECT_ROOT/blog-frontend" && npm run dev -- --port 3001) &
    BLOG_PID=$!
  fi
fi

cleanup() {
  kill "${BACKEND_PID:-}" "${WORKER_PID:-}" "${FRONTEND_PID:-}" "${BLOG_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait
