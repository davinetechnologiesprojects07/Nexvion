#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$RUN_DIR" "$LOG_DIR"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Nexvion already running (PID $(cat "$PID_FILE"))"
  exit 0
fi

cd "$APP_DIR"
nohup python3 -m http.server "$PORT" >> "$APP_LOG" 2>&1 &
echo $! > "$PID_FILE"
sleep 1
echo "Nexvion started on port $PORT (PID $(cat "$PID_FILE"))"
