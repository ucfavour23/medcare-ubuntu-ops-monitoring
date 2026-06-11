#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-/var/log/medcare-monitoring}"
REPORT_DIR="${REPORT_DIR:-/var/reports/medcare-monitoring}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

find "$LOG_DIR" -type f -name "*.log" -mtime +"$RETENTION_DAYS" -print -delete \
  >>"$LOG_DIR/cleanup.log" 2>&1 || true

find "$REPORT_DIR" -type f \( -name "*.txt" -o -name "*.json" \) -mtime +"$RETENTION_DAYS" -print -delete \
  >>"$LOG_DIR/cleanup.log" 2>&1 || true

echo "$TIMESTAMP cleanup_completed retention_days=$RETENTION_DAYS" >>"$LOG_DIR/cleanup.log"
