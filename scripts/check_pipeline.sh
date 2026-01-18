#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: check_pipeline.sh
# Purpose: Verify SIEM pipeline is healthy (ES, Wazuh, Filebeat, Suricata)
#
# Inputs: None
#
# Environment:
#   ES_URL (default: http://localhost:9200)
#
# Exit Codes:
#   0  - Pipeline healthy
#   1  - One or more components unhealthy
#   10 - Infrastructure failure (Docker unavailable)
# -----------------------------------------------------------------------------
set -euo pipefail

ES="${ES_URL:-http://localhost:9200}"
ERRORS=0

# Verify Docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "  ✗ Docker not available"
  exit 10
fi

echo "Checking SIEM pipeline health..."

# Elasticsearch
ES_STATUS=$(curl -s "$ES/_cluster/health" 2>/dev/null | jq -r '.status // "unreachable"') || ES_STATUS="unreachable"
if [[ "$ES_STATUS" == "green" || "$ES_STATUS" == "yellow" ]]; then
  echo "  ✓ Elasticsearch: $ES_STATUS"
else
  echo "  ✗ Elasticsearch: $ES_STATUS"
  ERRORS=$((ERRORS + 1))
fi

# Wazuh Agent
if docker exec wazuh-manager /var/ossec/bin/agent_control -l 2>/dev/null | grep -q "Active"; then
  echo "  ✓ Wazuh Agent: Active"
else
  echo "  ✗ Wazuh Agent: Not Active"
  ERRORS=$((ERRORS + 1))
fi

# Filebeat
if docker logs filebeat 2>&1 | grep -q "Harvester started"; then
  echo "  ✓ Filebeat: Harvesting"
else
  echo "  ✗ Filebeat: No harvesters"
  ERRORS=$((ERRORS + 1))
fi

# Suricata
if [[ -s logs/suricata/eve.jsonl ]]; then
  echo "  ✓ Suricata: Producing events"
else
  echo "  ⚠ Suricata: No EVE output"
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "Pipeline check failed ($ERRORS errors)"
  exit 1
fi

echo "Pipeline healthy"
exit 0
