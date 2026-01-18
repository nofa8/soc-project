#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: brute_force.sh
# Purpose: Generate brute-force authentication stimulus (deterministic, portable)
#
# Inputs: None (uses environment variables)
#
# Environment:
#   API_URL    (default: http://localhost)
#   ADMIN_USER (default: admin)
#   ATTEMPTS   (default: 5)
#
# Exit Codes:
#   0 - Stimulus generated successfully
# -----------------------------------------------------------------------------
set -euo pipefail

API="${API_URL:-http://localhost}"
USER="${ADMIN_USER:-admin}"
ATTEMPTS="${ATTEMPTS:-5}"

echo "[Stimulus] Brute Force: $ATTEMPTS attempts against $API/login"

for ((i=1; i<=ATTEMPTS; i++)); do
  curl -s -X POST "$API/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USER\",\"password\":\"attempt$i\"}" \
    > /dev/null 2>&1 || true
  echo "  Attempt $i sent"
done

echo "[Stimulus] Brute force complete"
exit 0
