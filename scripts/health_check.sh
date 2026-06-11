#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-/var/log/medcare-monitoring}"
REPORT_DIR="${REPORT_DIR:-/var/reports/medcare-monitoring}"
SERVICES="${SERVICES:-ssh cron docker}"
HOSTNAME_VALUE="$(hostname)"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

cpu_used_percent() {
  awk '/^cpu / {
    idle=$5
    total=0
    for (i=2; i<=NF; i++) total += $i
    if (total > 0) printf "%.2f", (1 - idle / total) * 100
  }' /proc/stat
}

memory_used_percent() {
  free | awk '/Mem:/ { printf "%.2f", ($3 / $2) * 100 }'
}

disk_used_percent() {
  df -P / | awk 'NR==2 { gsub("%", "", $5); print $5 }'
}

load_average() {
  awk '{ print $1 "," $2 "," $3 }' /proc/loadavg
}

service_status_json() {
  local first=true
  printf "{"
  for service in $SERVICES; do
    if systemctl is-active --quiet "$service"; then
      status="running"
    else
      status="stopped"
    fi

    if [ "$first" = false ]; then
      printf ","
    fi
    printf '"%s":"%s"' "$service" "$status"
    first=false
  done
  printf "}"
}

CPU="$(cpu_used_percent)"
MEMORY="$(memory_used_percent)"
DISK="$(disk_used_percent)"
LOAD="$(load_average)"
SERVICES_JSON="$(service_status_json)"

cat >"$LOG_DIR/latest-health.json" <<JSON
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$HOSTNAME_VALUE",
  "cpu_used_percent": $CPU,
  "memory_used_percent": $MEMORY,
  "disk_used_percent": $DISK,
  "load_average": "$LOAD",
  "services": $SERVICES_JSON
}
JSON

cat >>"$LOG_DIR/health-check.log" <<EOF
$TIMESTAMP host=$HOSTNAME_VALUE cpu=${CPU}% memory=${MEMORY}% disk=${DISK}% load=${LOAD}
EOF

cp "$LOG_DIR/latest-health.json" "$REPORT_DIR/latest-health.json"
