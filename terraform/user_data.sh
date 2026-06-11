#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${project_name}"
APP_PORT="${app_port}"
AWS_REGION="${aws_region}"
REPOSITORY_URL="${repository_url}"
APP_DIR="/opt/medcare-monitoring"

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  amazon-cloudwatch-agent \
  awscli \
  cron \
  docker.io \
  git \
  jq \
  python3-pip \
  python3-venv

systemctl enable --now docker

mkdir -p "$APP_DIR" /var/log/medcare-monitoring /var/reports/medcare-monitoring
chown -R ubuntu:ubuntu "$APP_DIR" /var/log/medcare-monitoring /var/reports/medcare-monitoring

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/medcare-monitoring/*.log",
            "log_group_name": "/medcare/ubuntu-ops",
            "log_stream_name": "{instance_id}/monitoring"
          },
          {
            "file_path": "/var/reports/medcare-monitoring/*.txt",
            "log_group_name": "/medcare/ubuntu-ops/reports",
            "log_stream_name": "{instance_id}/daily-report"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
JSON

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

cat >"$APP_DIR/README.txt" <<EOF
$PROJECT_NAME bootstrap completed.
AWS region: $AWS_REGION
Dashboard port: $APP_PORT
Repository: $REPOSITORY_URL
EOF

if [ -n "$REPOSITORY_URL" ]; then
  rm -rf "$APP_DIR/repo"
  git clone --depth 1 "$REPOSITORY_URL" "$APP_DIR/repo"
  chown -R ubuntu:ubuntu "$APP_DIR/repo"

  chmod +x "$APP_DIR/repo/scripts/"*.sh
  "$APP_DIR/repo/scripts/health_check.sh" || true

  python3 -m venv "$APP_DIR/.venv"
  "$APP_DIR/.venv/bin/pip" install --upgrade pip
  "$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/repo/app/requirements.txt"

  cat >/etc/systemd/system/medcare-dashboard.service <<SERVICE
[Unit]
Description=MedCare Ubuntu Operations Dashboard
After=network-online.target
Wants=network-online.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/repo/app
Environment=HEALTH_DATA_PATH=/var/log/medcare-monitoring/latest-health.json
Environment=REPORT_DIR=/var/reports/medcare-monitoring
ExecStart=$APP_DIR/.venv/bin/gunicorn --bind 0.0.0.0:$APP_PORT app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable --now medcare-dashboard

  echo "*/5 * * * * root $APP_DIR/repo/scripts/health_check.sh >> /var/log/medcare-monitoring/cron.log 2>&1" >/etc/cron.d/medcare-health-check
  echo "0 1 * * * root $APP_DIR/repo/scripts/log_cleanup.sh >> /var/log/medcare-monitoring/cleanup.log 2>&1" >/etc/cron.d/medcare-log-cleanup
fi

systemctl restart cron
