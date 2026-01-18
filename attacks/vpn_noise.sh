#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: vpn_noise.sh
# Purpose: Generate VPN probe stimulus (UDP packets to WireGuard port)
#
# Inputs: None
#
# Environment:
#   VPN_HOST (default: 127.0.0.1)
#   VPN_PORT (default: 51820)
#   PROBES   (default: 5)
#
# Exit Codes:
#   0 - Stimulus generated successfully
# -----------------------------------------------------------------------------
set -euo pipefail

HOST="${VPN_HOST:-127.0.0.1}"
PORT="${VPN_PORT:-51820}"
PROBES="${PROBES:-5}"

echo "[Stimulus] VPN UDP noise: $PROBES probes to $HOST:$PORT"

for ((i=1; i<=PROBES; i++)); do
  echo "probe_$i" | nc -u -w1 "$HOST" "$PORT" 2>/dev/null || true
  echo "  Probe $i sent"
done

echo "[Stimulus] VPN probing complete"
exit 0
