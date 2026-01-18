#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: check_alert.sh
# Purpose: Verify Wazuh detection fired in Elasticsearch
#
# Inputs:
#   $1 - Rule ID (string, required)
#   $2 - Minimum expected count (integer, required)
#
# Environment:
#   ES_URL         (default: http://localhost:9200)
#   ALERT_INDEX    (default: soc-logs-*)
#   ALERT_RETRIES  (default: 6)
#   ALERT_INTERVAL (default: 5)
#
# Exit Codes:
#   0  - Detection verified
#   1  - Detection failed after all retries
#   2  - Invalid usage / missing arguments
#   10 - Infrastructure failure (ES unreachable)
# -----------------------------------------------------------------------------
set -euo pipefail

# Validate arguments
if [[ $# -lt 2 ]]; then
  echo "Usage: check_alert.sh <rule_id> <min_count>"
  exit 2
fi

RULE_ID="$1"
MIN_COUNT="$2"

INDEX="${ALERT_INDEX:-soc-logs-*}"
RETRIES="${ALERT_RETRIES:-6}"
INTERVAL="${ALERT_INTERVAL:-5}"
ES="${ES_URL:-http://localhost:9200}"

# Verify ES is reachable
if ! curl -s "$ES/_cluster/health" >/dev/null 2>&1; then
  echo "  ✗ Elasticsearch unreachable at $ES"
  exit 10
fi

echo "  Waiting for alert indexing..."

for ((i=1; i<=RETRIES; i++)); do
  COUNT=$(curl -s "$ES/$INDEX/_search" \
    -H 'Content-Type: application/json' \
    -d "{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"term\":{\"rule.id\":\"$RULE_ID\"}},{\"range\":{\"@timestamp\":{\"gte\":\"now-10m\"}}}]}}}" \
    2>/dev/null | jq -r '.hits.total.value // 0')

  if [[ "$COUNT" -ge "$MIN_COUNT" ]]; then
    echo "  ✓ Rule $RULE_ID verified ($COUNT alerts, attempt $i)"
    exit 0
  fi

  echo "  Retry $i/$RETRIES: Rule $RULE_ID not yet indexed (got $COUNT)..."
  sleep "$INTERVAL"
done

echo "  ✗ Rule $RULE_ID NOT DETECTED after $((RETRIES * INTERVAL))s (expected ≥$MIN_COUNT)"
exit 1
