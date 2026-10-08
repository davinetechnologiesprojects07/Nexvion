#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$LOG_DIR"

case "${1:-show}" in
  show)   tail -n 50 "$APP_LOG" ;;
  follow) tail -f "$APP_LOG" ;;
  rotate)
    if [[ -s "$APP_LOG" ]]; then
      mv "$APP_LOG" "$APP_LOG.$(date +%Y%m%d-%H%M%S)"
      gzip "$LOG_DIR"/app.log.* 2>/dev/null || true
      : > "$APP_LOG"
      echo "Log rotated"
    fi ;;
  *) echo "Usage: $0 {show|follow|rotate}"; exit 1 ;;
esac
