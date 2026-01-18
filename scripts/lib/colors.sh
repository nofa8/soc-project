#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name: colors.sh
# Purpose: Terminal color definitions for consistent UX
#
# Usage: source scripts/lib/colors.sh
# -----------------------------------------------------------------------------

# Colors (safe for non-tty)
if [[ -t 1 ]]; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  NC=$(tput sgr0)
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  NC=""
fi

# Helper functions
success() { echo "${GREEN}✓ $*${NC}"; }
failure() { echo "${RED}✗ $*${NC}"; }
warning() { echo "${YELLOW}⚠ $*${NC}"; }
info()    { echo "${BLUE}ℹ $*${NC}"; }
