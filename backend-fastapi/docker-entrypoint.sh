#!/bin/sh
set -e

# Ensure the logs directory exists (bind-mounted directories may be empty)
mkdir -p /app/logs

# Fix permissions so the non-root user can write logs
echo "[ENTRYPOINT] Setting permissions for /app/logs"
chown -R appuser:appuser /app/logs 2>/dev/null || true
chmod -R 775 /app/logs 2>/dev/null || true
echo "[ENTRYPOINT] Permissions set for /app/logs"

# Drop privileges and start the application
exec gosu appuser "$@"
