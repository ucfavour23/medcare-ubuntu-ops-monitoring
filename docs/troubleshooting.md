# Troubleshooting

## Dashboard Does Not Load

1. Confirm the EC2 instance is running and has a public IP.
2. Confirm the security group allows inbound TCP port `80`.
3. Wait several minutes for user data to finish.
4. Connect by SSH and inspect the native systemd service:

```bash
sudo systemctl status medcare-dashboard --no-pager
sudo journalctl -u medcare-dashboard -n 100 --no-pager
curl http://localhost/health
curl http://localhost/api/metrics
```

## Dashboard Service Is Not Installed

Inspect the cloud-init log:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

Package downloads can fail temporarily. Re-run the relevant native Python and systemd commands from `terraform/user_data.sh` after network access is restored.

## Repository Was Not Cloned

The automatic deployment expects a public Git repository URL. Check the configured Terraform variable and cloud-init output:

```bash
terraform output
sudo grep -i clone /var/log/cloud-init-output.log
```

For a private repository, use a secure deployment method such as AWS Systems Manager or a CI/CD runner. Do not add a personal access token to user data.

## Service Shows "Not Detected"

The dashboard checks Linux process names, not systemd unit names. The default process names are `sshd` and `systemd`.

To monitor different processes, update the systemd unit environment with a comma-separated process list:

```bash
sudo systemctl edit medcare-dashboard
```

Add:

```ini
[Service]
Environment=MONITORED_SERVICES=sshd,systemd,nginx
```

Then run:

```bash
sudo systemctl daemon-reload
sudo systemctl restart medcare-dashboard
```

## SNS Email Alerts Do Not Arrive

- Confirm the SNS subscription using the email sent by AWS.
- Check spam or junk folders.
- Verify the CloudWatch alarm has the SNS topic under alarm actions.
- Remember that the alarm only enters `ALARM` after average CPU exceeds 80 percent for two consecutive five-minute periods.

## SSH Connection Fails

- Confirm `key_name` matches an existing EC2 key pair in `us-east-1`.
- Confirm the private key file has appropriate permissions.
- Confirm `ssh_allowed_cidr` includes the administrator's current public IP address.
- Use the Ubuntu AMI username: `ubuntu`.
