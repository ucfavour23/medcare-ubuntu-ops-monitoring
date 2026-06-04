#!/usr/bin/env bash
# Remove old compressed and rotated logs without touching active log files.

set -euo pipefail

LOG_DIR="${1:-/var/log}"
RETENTION_DAYS="${2:-14}"

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Retention days must be a non-negative number."
  exit 2
fi

if [[ ! -d "$LOG_DIR" ]]; then
  echo "ERROR: Log directory does not exist: $LOG_DIR"
  exit 1
fi

echo "Removing rotated logs older than ${RETENTION_DAYS} days from ${LOG_DIR}..."
find "$LOG_DIR" -type f \( -name "*.gz" -o -name "*.log.*" \) -mtime "+${RETENTION_DAYS}" -print -delete
echo "Log cleanup complete."
