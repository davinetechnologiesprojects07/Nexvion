#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"

echo "================================="
echo "       Nexvion Setup"
echo "================================="

echo "Project root: $PROJECT_ROOT"

echo ""
echo "Checking required application files..."

required_files=(
    "index.html"
    "products.html"
    "payment.html"
    "style.css"
    "products.css"
    "payment.css"
    "script.js"
    "payment.js"
    "logo.png"
)

missing_file=0

for file in "${required_files[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "[OK] $file"
    else
        echo "[MISSING] $file"
        missing_file=1
    fi
done

echo ""
echo "Preparing directories..."

mkdir -p "$LOG_DIR"

echo "[OK] Logs directory ready: $LOG_DIR"

echo ""

if [ "$missing_file" -ne 0 ]; then
    echo "[ERROR] Setup failed because required files are missing."
    exit 1
fi

echo "[SUCCESS] Nexvion setup completed."