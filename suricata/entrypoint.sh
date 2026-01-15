#!/bin/sh
set -e

echo "[*] Initializing Suricata rules"

# Update available sources
suricata-update update-sources

# Ensure Emerging Threats Open is enabled
suricata-update enable-source et/open

# Generate or update ruleset
suricata-update

# Optional debugging
ls -l /var/lib/suricata/rules/suricata.rules

echo "[*] Starting Suricata"
exec suricata "$@"