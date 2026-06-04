#!/usr/bin/env bash
# Exit with a warning when root disk usage reaches the configured threshold.

set -euo pipefail

THRESHOLD="${1:-80}"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$THRESHOLD" -lt 1 || "$THRESHOLD" -gt 100 ]]; then
  echo "ERROR: Threshold must be a number between 1 and 100."
  exit 2
fi

USAGE="$(df --output=pcent / | tail -n 1 | tr -dc '0-9')"

if [[ "$USAGE" -ge "$THRESHOLD" ]]; then
  echo "WARNING: Root disk usage is ${USAGE}%, above the ${THRESHOLD}% threshold."
  exit 1
fi

echo "OK: Root disk usage is ${USAGE}%, below the ${THRESHOLD}% threshold."
