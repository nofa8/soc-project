#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: firewall_scan.sh
# Purpose: Generate firewall block stimulus (connections to blocked ports)
#
# Inputs: None
#
# Environment:
#   TARGET_IP (default: 127.0.0.1)
#
# Exit Codes:
#   0 - Stimulus generated successfully
# -----------------------------------------------------------------------------
set -euo pipefail

TARGET="${TARGET_IP:-127.0.0.1}"

echo "[Stimulus] Firewall scan against $TARGET"

# Attempt blocked ports
for port in 22 3306 23 445; do
  curl -s --connect-timeout 2 "http://$TARGET:$port" 2>/dev/null || \
    echo "  Port $port: Connection blocked/timeout"
done

echo "[Stimulus] Firewall scan complete"
exit 0
