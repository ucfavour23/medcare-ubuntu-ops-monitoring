#!/usr/bin/env bash
# Basic Ubuntu server health report for MedCare operations.

set -euo pipefail

echo "=== MedCare Server Health Check ==="
echo "Hostname: $(hostname)"
echo "Date: $(date --utc '+%Y-%m-%d %H:%M:%S UTC')"
echo "Uptime: $(uptime -p)"
echo
echo "--- Load Average ---"
uptime
echo
echo "--- Memory Usage ---"
free -h
echo
echo "--- Root Disk Usage ---"
df -h /
echo
echo "--- Important Services ---"
for service in ssh docker; do
  if systemctl is-active --quiet "$service"; then
    echo "$service: healthy"
  else
    echo "$service: not running"
  fi
done
