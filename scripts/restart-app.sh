#!/usr/bin/env bash
set -euo pipefail
DIR="$(dirname "$0")"
"$DIR/stop-app.sh"
"$DIR/start-app.sh"
