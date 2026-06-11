#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <ubuntu-server-ip> <path-to-private-key.pem>"
  exit 1
fi

SERVER_IP="$1"
PRIVATE_KEY="$2"
REMOTE_DIR="/home/ubuntu/medcare-ubuntu-ops-monitoring"

rsync -avz --delete \
  --exclude ".git" \
  --exclude ".terraform" \
  --exclude "*.tfstate*" \
  -e "ssh -i $PRIVATE_KEY -o StrictHostKeyChecking=accept-new" \
  ./ "ubuntu@$SERVER_IP:$REMOTE_DIR/"

ssh -i "$PRIVATE_KEY" "ubuntu@$SERVER_IP" "cd $REMOTE_DIR && chmod +x scripts/*.sh && ./scripts/install_monitoring.sh"
