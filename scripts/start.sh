#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
PID_FILE="$LOG_DIR/nexvion.pid"
LOG_FILE="$LOG_DIR/nexvion.log"
PORT=8000

echo "================================="
echo "       Starting Nexvion"
echo "================================="

mkdir -p "$LOG_DIR"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        echo "[INFO] Nexvion is already running with PID $PID"
        exit 0
    else
        echo "[INFO] Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

cd "$PROJECT_ROOT"

nohup python -m http.server "$PORT" > "$LOG_FILE" 2>&1 &

PID=$!
echo "$PID" > "$PID_FILE"

sleep 2

if kill -0 "$PID" 2>/dev/null; then
    echo "[SUCCESS] Nexvion started successfully"
    echo "PID: $PID"
    echo "URL: http://localhost:$PORT"
    echo "Log file: $LOG_FILE"
else
    echo "[ERROR] Nexvion failed to start"
    rm -f "$PID_FILE"
    exit 1
fi