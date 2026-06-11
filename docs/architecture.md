# Architecture

## Overview

The MedCare Ubuntu Operations & Monitoring Platform is built around one monitored Ubuntu EC2 server. Terraform provisions the AWS resources, Bash scripts collect operating system health data, CloudWatch handles metrics and alarms, SNS sends email alerts, and a Flask dashboard displays the latest health state.

## Resource Flow

1. A cloud engineer pushes code to GitHub.
2. GitHub Actions validates Terraform, Python tests, and Docker image build.
3. Terraform creates EC2, IAM, SNS, CloudWatch alarms, and the security group.
4. EC2 user data installs Ubuntu packages, Docker, CloudWatch Agent, and cron.
5. Health scripts write JSON and log files to `/var/log/medcare-monitoring`.
6. The Flask dashboard reads the latest JSON health file.
7. CloudWatch alarms send notifications to the SNS email topic.

## AWS Components

| Component | Purpose |
| --- | --- |
| EC2 | Runs the Ubuntu monitoring workload |
| IAM Role | Grants the instance access to SSM and CloudWatch Agent |
| Security Group | Allows SSH and dashboard access from an approved CIDR |
| CloudWatch Agent | Collects memory, disk, CPU, and log data |
| CloudWatch Alarms | Detects CPU, disk, memory, and status check issues |
| SNS | Sends alert emails to operations support |

## Security Notes

- Replace `ssh_cidr` with your own public IP `/32`.
- Do not commit real `terraform.tfvars`.
- Use IAM roles instead of storing AWS credentials on EC2.
- Destroy resources after portfolio testing to avoid cost.
