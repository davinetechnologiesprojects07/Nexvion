#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$BACKUP_DIR"

STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="$BACKUP_DIR/nexvion-app-$STAMP.tar.gz"
tar -czf "$FILE" -C "$ROOT_DIR" app
echo "Backup created: $FILE"

# keep only the 5 newest backups
ls -1t "$BACKUP_DIR"/nexvion-app-*.tar.gz | tail -n +6 | xargs -r rm --
