# Draw.io Architecture Diagram Description

Use this description to recreate the architecture diagram in Draw.io, Lucidchart, Visio, or diagrams.net.

## Diagram Title

MediCare Ubuntu Operations & Monitoring Platform

## Layout

Use a left-to-right layout with four zones:

1. User and engineering access
2. AWS cloud boundary
3. Ubuntu EC2 runtime
4. Monitoring and alerting

## Components

### User and Engineering Access

- Cloud Engineer
  - Icon: user or laptop
  - Connects to Terraform with label: `terraform init / plan / apply`
- Operations User
  - Icon: user or browser
  - Connects to Security Group with label: `HTTP 80`
- Administrator
  - Icon: admin user or terminal
  - Connects to Security Group with label: `SSH 22 restricted CIDR`

### AWS Cloud Boundary

Draw a large rounded rectangle labeled `AWS us-east-1`.

Inside it, include:

- Terraform-managed resources group
- Security Group
- Ubuntu EC2 instance
- CloudWatch Alarm
- SNS Topic

### Ubuntu EC2 Runtime

Inside the EC2 instance, show:

- Ubuntu 22.04 LTS
- systemd service: `medcare-dashboard`
- Gunicorn
- Flask monitoring dashboard
- psutil metrics collection
- Bash operations scripts

Connect them vertically:

`Ubuntu EC2 -> systemd -> Gunicorn -> Flask Dashboard -> psutil`

Add endpoint labels next to the Flask dashboard:

- `/`
- `/health`
- `/api/metrics`

### Monitoring and Alerting

Place these to the right of EC2:

- EC2 `CPUUtilization` metric
- CloudWatch high CPU alarm
- SNS operations alerts topic
- Email subscriber

Connect them:

`EC2 CPUUtilization -> CloudWatch Alarm -> SNS Topic -> Email Notification`

## Recommended Shapes and Colors

- AWS boundary: light orange background, orange border
- EC2: orange compute icon
- Security Group: shield icon
- systemd/Gunicorn/Flask: blue application boxes
- Bash scripts: gray terminal icon
- CloudWatch: green monitoring icon
- SNS/email: purple notification icon

## Key Labels

- `Infrastructure as Code: Terraform`
- `Native Ubuntu deployment: Python + Gunicorn + systemd`
- `Native Ubuntu deployment`
- `Health endpoint: /health`
- `Metrics endpoint: /api/metrics`
- `Alert path: CloudWatch -> SNS -> Email`

## Security Callouts

Add three small callout notes:

- `SSH restricted to administrator CIDR`
- `Root volume encrypted`
- `IMDSv2 required`

## Diagram Caption

Terraform provisions a free-tier friendly Ubuntu EC2 monitoring server. The dashboard runs as a native systemd service, exposes health and metrics endpoints, and integrates with CloudWatch and SNS for alert notifications.
