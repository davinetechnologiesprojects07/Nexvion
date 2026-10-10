#!/usr/bin/env bash

echo "================================="
echo "     Nexvion System Check"
echo "================================="

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "[OK] $1 is installed"
    else
        echo "[MISSING] $1 is not installed"
    fi
}

check_command git
check_command python
check_command docker
check_command curl

echo ""

if docker info >/dev/null 2>&1; then
    echo "[OK] Docker Engine is running"
else
    echo "[ERROR] Docker Engine is not running"
fi

echo ""

echo "Current directory: $(pwd)"
echo "Current Git branch: $(git branch --show-current)"

echo ""
echo "System check completed."