#!/bin/bash
set -e

# WAZUH_MANAGER is set in ossec.conf already


# Start Wazuh Agent
echo "Starting Wazuh Agent..."
/var/ossec/bin/wazuh-control start

# Keep container alive and stream logs
echo "Tailing ossec.log..."
tail -F /var/ossec/logs/ossec.log
