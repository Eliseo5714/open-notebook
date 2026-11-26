#!/bin/bash
# Arranca Open Notebook sin Docker: SurrealDB nativo + API + worker + frontend.
set -e
cd "$(dirname "$0")"
export PATH="$HOME/.surrealdb:$PATH"
mkdir -p .local-run surreal_data

is_running() { [ -f ".local-run/$1.pid" ] && kill -0 "$(cat ".local-run/$1.pid")" 2>/dev/null; }

if is_running surrealdb; then
  echo "SurrealDB ya está corriendo (pid $(cat .local-run/surrealdb.pid))"
else
  nohup surreal start --user root --pass root "rocksdb:./surreal_data/mydatabase.db" \
    > .local-run/surrealdb.log 2>&1 &
  echo $! > .local-run/surrealdb.pid
  echo "SurrealDB arrancado (pid $!) -> .local-run/surrealdb.log"
  sleep 2
fi

if is_running api; then
  echo "API ya está corriendo (pid $(cat .local-run/api.pid))"
else
  nohup uv run --env-file .env run_api.py > .local-run/api.log 2>&1 &
  echo $! > .local-run/api.pid
  echo "API arrancada (pid $!) -> .local-run/api.log"
fi

if is_running worker; then
  echo "Worker ya está corriendo (pid $(cat .local-run/worker.pid))"
else
  nohup uv run --env-file .env surreal-commands-worker --import-modules commands --max-tasks 5 \
    > .local-run/worker.log 2>&1 &
  echo $! > .local-run/worker.pid
  echo "Worker arrancado (pid $!) -> .local-run/worker.log"
fi

if is_running frontend; then
  echo "Frontend ya está corriendo (pid $(cat .local-run/frontend.pid))"
else
  ROOT="$(pwd)"
  cd frontend
  nohup npm run dev > "$ROOT/.local-run/frontend.log" 2>&1 &
  echo $! > "$ROOT/.local-run/frontend.pid"
  cd "$ROOT"
  echo "Frontend arrancado -> .local-run/frontend.log"
fi

echo ""
echo "Frontend:  http://localhost:3000"
echo "API docs:  http://localhost:5055/docs"
echo "Database:  http://localhost:8000"
