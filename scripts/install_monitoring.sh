#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/medcare-monitoring}"
SERVICE_USER="${SERVICE_USER:-ubuntu}"

sudo mkdir -p "$APP_DIR"/{app,scripts} /var/log/medcare-monitoring /var/reports/medcare-monitoring
sudo cp -R app/* "$APP_DIR/app/"
sudo cp scripts/health_check.sh scripts/log_cleanup.sh "$APP_DIR/scripts/"
sudo chmod +x "$APP_DIR/scripts/"*.sh
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR" /var/log/medcare-monitoring /var/reports/medcare-monitoring

python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/app/requirements.txt"

sudo tee /etc/systemd/system/medcare-dashboard.service >/dev/null <<EOF
[Unit]
Description=MedCare Ubuntu Operations Dashboard
After=network.target

[Service]
User=$SERVICE_USER
WorkingDirectory=$APP_DIR/app
Environment=HEALTH_DATA_PATH=/var/log/medcare-monitoring/latest-health.json
Environment=REPORT_DIR=/var/reports/medcare-monitoring
ExecStart=$APP_DIR/.venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now medcare-dashboard

sudo tee /etc/cron.d/medcare-health-check >/dev/null <<EOF
*/5 * * * * root $APP_DIR/scripts/health_check.sh >> /var/log/medcare-monitoring/cron.log 2>&1
0 1 * * * root $APP_DIR/scripts/log_cleanup.sh >> /var/log/medcare-monitoring/cleanup.log 2>&1
EOF

sudo systemctl restart cron
echo "MedCare monitoring installed. Dashboard runs on port 5000."
