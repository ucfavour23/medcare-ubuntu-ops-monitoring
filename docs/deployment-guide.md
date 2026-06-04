# Deployment Guide

## Prerequisites

- An AWS account with permission to create EC2, security group, CloudWatch, and SNS resources
- AWS CLI credentials configured locally through an AWS profile or another secure method
- Terraform 1.5 or later
- An existing EC2 key pair if SSH access is required
- A public Git repository URL if the dashboard should deploy automatically

## 1. Prepare Terraform Variables

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`. The `.tfvars` file is ignored by Git.

```hcl
key_name              = "your-existing-key-pair"
ssh_allowed_cidr      = "203.0.113.10/32"
http_allowed_cidr     = "0.0.0.0/0"
alert_email           = "operations@example.com"
github_repository_url = "https://github.com/your-user/medcare-ubuntu-ops-monitoring.git"
```

Do not place AWS access keys or secret keys in this file.

## 2. Deploy the AWS Resources

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Type `yes` when Terraform asks for confirmation. If `alert_email` is set, open the AWS SNS confirmation email and confirm the subscription.

## 3. Open the Dashboard

After user data finishes, Terraform prints `dashboard_url`. Open it in a browser:

```bash
terraform output -raw dashboard_url
```

Bootstrap can take a few minutes because Ubuntu installs Python packages, clones the repository, creates a virtual environment, installs the dashboard dependencies, and starts a systemd service.

The dashboard is available at `/`, its health endpoint is `/health`, and live metrics are also available as JSON at `/api/metrics`.

## 4. Manual Dashboard Deployment

Use these steps if `github_repository_url` was left empty:

```bash
ssh -i your-key.pem ubuntu@SERVER_PUBLIC_IP
git clone https://github.com/your-user/medcare-ubuntu-ops-monitoring.git
cd medcare-ubuntu-ops-monitoring/app
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
sudo .venv/bin/gunicorn --bind 0.0.0.0:80 --workers 2 app:app
```

For a persistent manual service, create a systemd unit similar to `terraform/user_data.sh`.

## 5. Run the Operations Scripts

```bash
cd ~/medcare-ubuntu-ops-monitoring
chmod +x scripts/*.sh
sudo ./scripts/health_check.sh
sudo ./scripts/disk_check.sh 80
sudo ./scripts/log_cleanup.sh /var/log 14
```

## 6. Verify Monitoring

In the AWS console, open CloudWatch, select **Alarms**, and find the MedCare high CPU alarm. The alarm uses the native EC2 `CPUUtilization` metric and sends state changes to the SNS topic.

## Cleanup

```bash
cd terraform
terraform destroy
```

Review the plan and type `yes`. This removes the EC2 instance, security group, alarm, SNS topic, and email subscription.
