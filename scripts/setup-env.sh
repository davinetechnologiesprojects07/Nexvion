#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "==> Installing base packages"
sudo apt-get update -y
sudo apt-get install -y curl git tar gzip jq net-tools

echo "==> Creating runtime directories"
mkdir -p "$RUN_DIR" "$LOG_DIR" "$BACKUP_DIR"

echo "==> Environment ready"
