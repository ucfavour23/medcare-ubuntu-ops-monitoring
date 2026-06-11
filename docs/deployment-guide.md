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
sudo tail -f /var/log/medcare-monitoring/health-check.log
```

## 6. Destroy When Finished

```bash
cd terraform
terraform destroy
```
