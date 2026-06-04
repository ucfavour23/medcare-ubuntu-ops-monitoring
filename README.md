# MediCare Ubuntu Operations & Monitoring Platform

A cloud engineering portfolio project that provisions an Ubuntu operations server on AWS and runs a lightweight monitoring dashboard with Terraform, Python, Gunicorn, systemd, CloudWatch, SNS, and GitHub Actions.

## Business Problem

MediCare Health Services depends on Ubuntu servers to support internal healthcare applications. The operations team needs a simple way to see server health, detect high resource usage, confirm key services are running, and receive alerts before server issues affect staff or patients.

The organization also needs repeatable infrastructure setup. Manual server builds are slow, inconsistent, and difficult to review during audits or handovers.

## Solution Overview

This project creates a free-tier friendly AWS monitoring environment:

- Terraform provisions the EC2 instance, security group, SNS topic, email subscription, and CloudWatch CPU alarm.
- EC2 user data installs Python dependencies and runs the Flask dashboard as a native systemd service.
- The dashboard displays hostname, UTC time, uptime, CPU, memory, disk usage, and process health.
- `/health` supports health checks and `/api/metrics` exposes JSON metrics for future automation.
- Bash scripts provide command-line health checks, disk threshold checks, and safe rotated log cleanup.
- GitHub Actions validates Python tests, shell syntax, Terraform formatting, and Terraform configuration.

## Architecture

```mermaid
flowchart LR
    Engineer[Cloud Engineer] -->|terraform apply| Terraform[Terraform]
    Terraform --> AWS[AWS us-east-1]
    AWS --> EC2[Ubuntu EC2 Instance]
    User[Operations User] -->|HTTP 80| SG[Security Group]
    Admin[Administrator] -->|SSH 22 restricted CIDR| SG
    SG --> EC2
    EC2 --> Systemd[systemd Service]
    Systemd --> Gunicorn[Gunicorn]
    Gunicorn --> Flask[Flask Monitoring Dashboard]
    Flask --> Metrics[/api/metrics]
    Flask --> Health[/health]
    EC2 --> Scripts[Bash Operations Scripts]
    EC2 --> CWMetric[EC2 CPUUtilization]
    CWMetric --> Alarm[CloudWatch Alarm]
    Alarm --> SNS[SNS Topic]
    SNS --> Email[Email Notification]
```

For a Draw.io-ready diagram brief, see [docs/architecture-diagram-drawio.md](docs/architecture-diagram-drawio.md).

## Technologies Used

| Area | Technologies |
| --- | --- |
| Cloud | AWS EC2, Security Groups, CloudWatch, SNS |
| Infrastructure as Code | Terraform |
| Operating System | Ubuntu 22.04 LTS |
| Application | Python 3, Flask, psutil, Gunicorn |
| Service Management | systemd |
| Operations Automation | Bash |
| CI/CD Validation | GitHub Actions |

## Repository Structure

```text
app/                 Flask dashboard, tests, requirements
scripts/             Ubuntu health, disk, and log cleanup scripts
terraform/           AWS infrastructure, user data, tfvars example
docs/                Deployment, troubleshooting, reviews, checklist, diagram brief
architecture/        Architecture notes
screenshots/         Portfolio screenshots
.github/workflows/   CI validation workflow
```

## Deployment Steps

### 1. Prerequisites

- AWS account with permission to create EC2, Security Group, CloudWatch, and SNS resources
- Terraform 1.5 or later
- AWS credentials configured locally through the AWS CLI, environment variables, or an AWS profile
- Existing EC2 key pair if SSH access is required
- Public GitHub repository URL for automatic EC2 bootstrap deployment

### 2. Configure Variables

Copy the example file and edit the values:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Example:

```hcl
key_name              = "your-existing-key-pair"
ssh_allowed_cidr      = "203.0.113.10/32"
http_allowed_cidr     = "0.0.0.0/0"
alert_email           = "operations@example.com"
github_repository_url = "https://github.com/your-user/medcare-ubuntu-ops-monitoring.git"
```

Do not commit `terraform.tfvars`, AWS keys, private keys, account IDs, or patient data.

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After deployment, confirm the SNS email subscription if `alert_email` was configured.

### 4. Open the Dashboard

```bash
terraform output -raw dashboard_url
```

Endpoints:

- `/` - monitoring dashboard
- `/health` - health check endpoint
- `/api/metrics` - JSON metrics endpoint

### 5. Run Local App Tests

```bash
cd app
python -m pip install -r requirements.txt
python -m unittest -v
```

### 6. Run Operations Scripts on Ubuntu

```bash
chmod +x scripts/*.sh
sudo ./scripts/health_check.sh
sudo ./scripts/disk_check.sh 80
sudo ./scripts/log_cleanup.sh /var/log 14
```

### 7. Cleanup

```bash
cd terraform
terraform destroy
```

Review the destroy plan before confirming.

## Screenshots

Add sanitized screenshots to `screenshots/` before publishing the portfolio repository:

- `dashboard-overview.png` - browser view of the monitoring dashboard
- `health-endpoint.png` - `/health` response
- `metrics-endpoint.png` - `/api/metrics` response
- `terraform-apply.png` - successful Terraform apply output with sensitive values hidden
- `cloudwatch-alarm.png` - CloudWatch alarm configuration
- `sns-subscription.png` - confirmed SNS subscription with email redacted
- `github-actions-success.png` - successful CI workflow run

## Skills Demonstrated

- Cloud infrastructure provisioning with Terraform
- AWS EC2, security group, CloudWatch, and SNS configuration
- Linux server administration on Ubuntu
- Python Flask application development
- System metrics collection with psutil
- Native Linux service deployment with systemd
- Bash scripting for operational checks and maintenance
- CI validation with GitHub Actions
- Security-minded documentation and secret hygiene
- Portfolio-ready architecture and deployment communication

## Production Readiness Notes

This project is suitable for a cloud portfolio demonstration. Before real healthcare production use, add HTTPS, authentication, private networking, centralized logs, backup and patching procedures, least-privilege IAM, compliance controls, and a formal incident response process.

See [docs/production-readiness-review.md](docs/production-readiness-review.md) and [docs/project-completion-checklist.md](docs/project-completion-checklist.md) for the final review items.
