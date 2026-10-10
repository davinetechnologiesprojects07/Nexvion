#!/usr/bin/env bash

URL="http://localhost:8000"

echo "================================="
echo "      Nexvion Health Check"
echo "================================="

echo "Checking: $URL"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || true)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "[SUCCESS] Nexvion is healthy"
    echo "HTTP Status: $HTTP_STATUS"
    exit 0
else
    echo "[ERROR] Nexvion is not healthy"
    echo "HTTP Status: $HTTP_STATUS"
    exit 1
fi