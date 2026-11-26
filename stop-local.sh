#!/bin/bash
# Para todos los procesos de Open Notebook arrancados por run-local.sh
cd "$(dirname "$0")"
for svc in frontend worker api surrealdb; do
  f=".local-run/$svc.pid"
  if [ -f "$f" ]; then
    pid=$(cat "$f")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      echo "Parado $svc (pid $pid)"
    fi
    rm -f "$f"
  fi
done
