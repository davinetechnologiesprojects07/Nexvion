#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$PROJECT_ROOT/logs/nexvion.pid"

echo "================================="
echo "       Stopping Nexvion"
echo "================================="

if [ ! -f "$PID_FILE" ]; then
    echo "[INFO] Nexvion does not appear to be running."
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Stopping Nexvion process $PID..."
    kill "$PID"

    sleep 2

    if kill -0 "$PID" 2>/dev/null; then
        echo "[ERROR] Nexvion process $PID is still running."
        exit 1
    else
        rm -f "$PID_FILE"
        echo "[SUCCESS] Nexvion stopped successfully."
    fi
else
    echo "[INFO] Process $PID is not running."
    rm -f "$PID_FILE"
    echo "[INFO] Removed stale PID file."
fi