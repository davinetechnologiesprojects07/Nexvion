#!/usr/bin/env bash
source "$(dirname "$0")/config.sh"

echo "=== OS ===";      grep PRETTY_NAME /etc/os-release
echo "=== User ===";    whoami
echo "=== CPU ===";     nproc
echo "=== Memory ===";  free -h | head -2
echo "=== Disk ===";    df -h / | tail -1
echo "=== Port $PORT ==="
(ss -ltn 2>/dev/null | grep ":$PORT ") || echo "nothing listening"
echo "=== Tools ==="
for t in git curl docker kubectl terraform ansible java; do
  if command -v "$t" >/dev/null 2>&1; then echo "installed: $t"; else echo "missing:   $t"; fi
done
