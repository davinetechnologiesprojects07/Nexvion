#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "==> Removing backups older than 7 days"
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "==> Removing rotated logs older than 7 days"
find "$LOG_DIR" -name "app.log.*" -mtime +7 -delete 2>/dev/null || true

if command -v docker >/dev/null 2>&1; then
  echo "==> Pruning unused Docker objects"
  docker system prune -f
fi
echo "Cleanup complete"
