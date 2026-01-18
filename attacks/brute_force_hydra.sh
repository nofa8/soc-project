#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: brute_force_hydra.sh
# Purpose: Generate brute-force stimulus using Hydra (realism layer, optional)
#
# Inputs: None
#
# Environment:
#   API_URL    (default: http://localhost)
#   ADMIN_USER (default: admin)
#
# Exit Codes:
#   0 - Stimulus generated successfully
#   2 - Hydra not installed (graceful skip)
#
# Notes:
#   - This script is OPTIONAL; brute_force.sh is the portable default
#   - Uses intentionally small wordlist (10 passwords) per ethical guidelines
# -----------------------------------------------------------------------------
set -euo pipefail

# Graceful skip if Hydra not installed
if ! command -v hydra >/dev/null 2>&1; then
  echo "[Stimulus] Hydra not installed; skipping"
  exit 2
fi

API="${API_URL:-http://localhost}"
USER="${ADMIN_USER:-admin}"

# Extract host and port from API_URL
HOST=$(echo "$API" | sed -E 's|https?://||' | cut -d/ -f1 | cut -d: -f1)
PORT=$(echo "$API" | sed -E 's|https?://||' | cut -d: -f2 | cut -d/ -f1)
PORT="${PORT:-80}"

# Create temporary wordlist (intentionally small)
WORDLIST=$(mktemp)
cat > "$WORDLIST" << 'EOF'
password
123456
admin
password123
letmein
welcome
monkey
dragon
master
qwerty
EOF

echo "[Stimulus] Hydra brute force against $HOST:$PORT (10 attempts)"

# Run Hydra against HTTP POST form
# Format: /login:username=^USER^&password=^PASS^:F=401
hydra -l "$USER" -P "$WORDLIST" "$HOST" -s "$PORT" \
  http-post-form "/login:username=^USER^&password=^PASS^:F=401" \
  -t 4 -w 2 -f 2>/dev/null || true

rm -f "$WORDLIST"

echo "[Stimulus] Hydra brute force complete"
exit 0
