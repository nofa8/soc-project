#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: timing.sh
# Purpose: Reusable timing and retry utilities
#
# Functions:
#   wait_with_backoff <retries> <interval> <command...>
#     - Retries command up to N times with fixed interval
#     - Returns 0 on success, 1 on exhaustion
# -----------------------------------------------------------------------------

wait_with_backoff() {
  local retries=$1
  local interval=$2
  shift 2

  for ((i=1; i<=retries; i++)); do
    if "$@"; then
      return 0
    fi
    sleep "$interval"
  done
  return 1
}
