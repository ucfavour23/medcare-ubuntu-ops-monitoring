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

1. Confirm the expected access path:

```bash
terraform -chdir=terraform output dashboard_url
```

2. If using HTTPS, confirm Caddy is running:

```bash
sudo systemctl status caddy
sudo journalctl -u caddy --since "30 minutes ago"
```

3. If using temporary HTTP by IP, confirm the security group allows your IP to port `5000`.

4. Check service status:

```bash
sudo systemctl status medcare-dashboard
```

5. Review app logs:

```bash
journalctl -u medcare-dashboard --since "30 minutes ago"
```

## Browser Shows Not Secure

`http://<public-ip>:5000` is expected to show as not secure because it is plain HTTP. Use a domain-backed HTTPS deployment for public access.

1. Point a DNS A record such as `ops.example.com` to the EC2 public IP.
2. Set `dashboard_domain` and `certificate_email` in `terraform.tfvars`.
3. Run `terraform apply`.
4. Open the `https://` URL from `terraform output dashboard_url`.

Confirm Caddy has a certificate:

```bash
sudo caddy list-certificates
```

Confirm the Flask app is behind the proxy:

```bash
curl -I http://127.0.0.1:5000
curl -I https://YOUR_DOMAIN
```
