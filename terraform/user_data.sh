#!/usr/bin/env bash
# EC2 bootstrap script: deploys the dashboard natively with Python and systemd.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl git python3 python3-venv python3-pip

REPOSITORY_URL="${repository_url}"
INSTALL_DIR="/opt/medcare-ubuntu-ops-monitoring"
APP_DIR="$INSTALL_DIR/app"
SERVICE_NAME="medcare-dashboard"

if [[ -n "$REPOSITORY_URL" ]]; then
  git clone "$REPOSITORY_URL" "$INSTALL_DIR"
  chown -R ubuntu:ubuntu "$INSTALL_DIR"

  python3 -m venv "$APP_DIR/.venv"
  "$APP_DIR/.venv/bin/pip" install --upgrade pip
  "$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

  cat >/etc/systemd/system/$SERVICE_NAME.service <<SERVICE
[Unit]
Description=MedCare Ubuntu Operations Monitoring Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_DIR
Environment=MONITORED_SERVICES=sshd,systemd
ExecStart=$APP_DIR/.venv/bin/gunicorn --bind 0.0.0.0:80 --workers 2 app:app
Restart=always
RestartSec=5
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable --now "$SERVICE_NAME"
fi
