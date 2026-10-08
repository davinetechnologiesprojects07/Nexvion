#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"
  echo "Nexvion stopped"
else
  rm -f "$PID_FILE"
  echo "Nexvion is not running"
fi
