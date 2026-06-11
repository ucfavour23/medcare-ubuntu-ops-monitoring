# Operations Runbook

## High CPU Alert

1. Check the CloudWatch alarm details.
2. Connect with SSM Session Manager or SSH.
3. Run `top` or `htop`.
4. Identify the process using the most CPU.
5. Restart the affected service only if necessary.
6. Add notes to the support handover.

## High Disk Alert

1. Run `df -h`.
2. Run `sudo du -xh /var/log | sort -h | tail`.
3. Confirm `/var/log/medcare-monitoring/cleanup.log`.
4. Increase retention cleanup only after confirming business requirements.

## Service Down

1. Check service status:

```bash
sudo systemctl status <service>
```

2. Review logs:

```bash
journalctl -u <service> --since "30 minutes ago"
```

3. Restart service:

```bash
sudo systemctl restart <service>
```

4. Confirm the next health check returns `running`.

## Dashboard Not Loading

1. Confirm security group allows your IP to port `5000`.
2. Check service status:

```bash
sudo systemctl status medcare-dashboard
```

3. Review app logs:

```bash
journalctl -u medcare-dashboard --since "30 minutes ago"
```
