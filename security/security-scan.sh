#!/bin/bash
set -e

echo "=== Nexvion Secret Scan ==="
trivy fs --scanners secret .

echo "=== Nexvion Image Scan ==="
trivy image --severity HIGH,CRITICAL nidhi8901/nexvion:2
