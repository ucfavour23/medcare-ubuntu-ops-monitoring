# Screenshot Evidence Guide

This project keeps GitHub documentation screenshots in `docs/screenshots/`.

## Included Evidence

| File | Purpose |
| --- | --- |
| `dashboard-local.png` | Local Docker dashboard running with sample Ubuntu health data |
| `api-health.png` | `/api/health` endpoint returning dashboard model JSON |
| `tests-passing.png` | Python test suite passing |
| `terraform-validate.png` | Terraform configuration validation evidence |
| `docker-build.png` | Docker image build evidence |
| `terraform-apply.png` | Successful `terraform apply` summary and outputs |
| `cloudwatch-alarms.png` | AWS CloudWatch alarms for CPU, memory, disk, and status checks |
| `sns-email-confirmation.png` | Confirmed SNS email subscription |
| `ec2-dashboard-live.png` | Dashboard opened from the EC2 public IP and app port |
| `ec2-systemd-status.png` | EC2 SSM evidence showing `amazon-cloudwatch-agent` and `medcare-dashboard` active |
| `github-actions-ci.png` | GitHub Actions workflow evidence from `.github/workflows/ci.yml` |

## Note On GitHub Actions

The local environment could not reach GitHub during capture, so `github-actions-ci.png` documents the configured workflow file rather than a live GitHub Actions run page. After pushing the repository, replace it with a screenshot of the passing workflow run if browser or GitHub CLI access is available.

## Recommended Capture Commands

Deployment evidence can be refreshed with:

```bash
terraform -chdir=terraform output
aws cloudwatch describe-alarms --alarm-name-prefix medcare-ubuntu-ops-portfolio
aws sns list-subscriptions-by-topic --topic-arn <SNS_TOPIC_ARN>
aws ssm send-command --instance-ids <INSTANCE_ID> --document-name AWS-RunShellScript --parameters commands="systemctl status medcare-dashboard --no-pager && systemctl status amazon-cloudwatch-agent --no-pager"
```

Then save screenshots into `docs/screenshots/` using the filenames above.
