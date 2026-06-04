# Final Project Completion Checklist

Use this checklist before publishing the repository link on a resume, LinkedIn profile, or portfolio page.

## Repository

- [x] Clear README with business problem, architecture, deployment, screenshots, and skills
- [x] Terraform configuration included
- [x] Flask dashboard source code included
- [x] Health endpoint and metrics endpoint implemented
- [x] Bash monitoring scripts included
- [x] GitHub Actions workflow included
- [x] `.gitignore` excludes secrets, state files, virtual environments, and private keys
- [x] `terraform.tfvars.example` included

## Local Validation

- [ ] Run `python -m unittest -v` from `app/`
- [ ] Run `bash -n scripts/*.sh terraform/user_data.sh`
- [ ] Run `terraform -chdir=terraform fmt -check`
- [ ] Run `terraform -chdir=terraform init -backend=false`
- [ ] Run `terraform -chdir=terraform validate`

## AWS Demo

- [ ] Create or confirm an EC2 key pair
- [ ] Set `ssh_allowed_cidr` to your public IP with `/32`
- [ ] Set `alert_email` to a safe demonstration email
- [ ] Run `terraform plan`
- [ ] Run `terraform apply`
- [ ] Confirm SNS email subscription
- [ ] Open the Terraform `dashboard_url`
- [ ] Verify `/health`
- [ ] Verify `/api/metrics`
- [ ] Confirm the CloudWatch alarm exists
- [ ] Run the Bash scripts on the Ubuntu instance

## Screenshots

- [ ] Dashboard overview
- [ ] Health endpoint response
- [ ] Metrics endpoint response
- [ ] Terraform apply success
- [ ] CloudWatch alarm
- [ ] SNS subscription with email redacted
- [ ] GitHub Actions success

## Security Review

- [ ] No AWS credentials committed
- [ ] No private keys committed
- [ ] No `.tfstate` files committed
- [ ] No real patient data or protected health information used
- [ ] Screenshots redact account IDs, emails, public IPs if desired, and private details

## Portfolio Presentation

- [ ] Add the architecture diagram image to `architecture/` or `screenshots/`
- [ ] Add screenshot images to `screenshots/`
- [ ] Push repository to GitHub
- [ ] Confirm GitHub Actions passes
- [ ] Add a short project summary to resume or LinkedIn
- [ ] Destroy AWS resources after demo if they are no longer needed
