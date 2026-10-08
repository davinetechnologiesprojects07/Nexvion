#!/usr/bin/env bash
# Shared settings for all Nexvion scripts
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
RUN_DIR="$ROOT_DIR/run"
LOG_DIR="$ROOT_DIR/logs"
BACKUP_DIR="$ROOT_DIR/backups"
PID_FILE="$RUN_DIR/nexvion.pid"
APP_LOG="$LOG_DIR/app.log"
PORT="${PORT:-8088}"
