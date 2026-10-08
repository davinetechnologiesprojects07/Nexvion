#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/config.sh"

BASE="${1:-http://localhost:$PORT}"
FAIL=0
for page in index.html products.html payment.html style.css script.js; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/$page")
  if [[ "$code" == "200" ]]; then
    echo "OK    $page ($code)"
  else
    echo "FAIL  $page ($code)"
    FAIL=1
  fi
done
exit $FAIL
