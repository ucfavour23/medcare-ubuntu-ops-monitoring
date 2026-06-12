# Deployment Guide

## Prerequisites

- AWS account
- AWS CLI configured locally
- Terraform installed
- Existing EC2 key pair if you want SSH access
- Git Bash, WSL Ubuntu, or a Linux shell for deployment scripts

## 1. Configure AWS Credentials

```bash
aws configure
```

Use an IAM user or role with permission to create EC2, IAM, CloudWatch, and SNS resources.

## 2. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Update:

```hcl
alert_email = "your-email@example.com"
key_name    = "your-existing-keypair-name"
ssh_cidr    = "YOUR_PUBLIC_IP/32"
```

For a secure recruiter-facing dashboard, also configure a domain:

```hcl
dashboard_domain      = "ops.example.com"
certificate_email    = "your-email@example.com"
public_dashboard_cidr = "0.0.0.0/0"
```

Create an A record for `dashboard_domain` that points to the EC2 public IP. A raw IP address on port `5000` will always show as not secure because it uses HTTP and cannot receive a normal trusted browser certificate.

## 3. Deploy Infrastructure

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, confirm the SNS email subscription.

## 4. Deploy Monitoring App

From the repository root:

```bash
chmod +x scripts/*.sh
./scripts/deploy_to_ec2.sh <EC2_PUBLIC_IP> <PATH_TO_PRIVATE_KEY.pem>
```

## 5. Verify Services On EC2

```bash
sudo systemctl status amazon-cloudwatch-agent
sudo systemctl status medcare-dashboard
sudo systemctl status caddy
sudo tail -f /var/log/medcare-monitoring/health-check.log
```

If `dashboard_domain` is set, open the HTTPS Terraform output:

```bash
terraform output dashboard_url
```

## 6. Capture Portfolio Evidence

Save these screenshots in `docs/screenshots/`:

- `terraform-apply.png`
- `cloudwatch-alarms.png`
- `sns-email-confirmation.png`
- `github-actions-ci.png`
- `ec2-dashboard-live.png`
- `ec2-systemd-status.png`

See `docs/screenshots.md` for the exact evidence checklist.

## 7. Destroy When Finished

```bash
cd terraform
terraform destroy
```
