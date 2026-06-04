# Client Explanation

## What This Platform Solves

MedCare Health Services depends on Ubuntu servers to run internal healthcare applications. When a server becomes overloaded, runs out of disk space, or loses an important service, staff may notice only after users are affected.

This platform gives the operations team a simple view of server health and an early warning when CPU usage remains high.

## What the Team Can See

The web dashboard displays:

- Server hostname and current UTC time
- CPU, memory, and root disk usage
- Server uptime
- Health status for selected service processes
- A JSON metrics endpoint for future automation

The included Bash scripts allow administrators to run a detailed health report, check disk usage against a threshold, and remove old rotated log files.

## How Alerting Works

AWS CloudWatch monitors the EC2 instance's CPU usage. If average CPU usage is above 80 percent for 10 minutes, CloudWatch changes the alarm state and publishes a message to an SNS topic. Confirmed email subscribers receive the alert.

## Business Benefits

- Earlier awareness of performance problems
- Faster troubleshooting through a central health view
- Consistent deployment using Terraform, Python, Gunicorn, and systemd
- Repeatable operational checks using Bash scripts
- Reduced risk of manual infrastructure configuration errors

## Production Considerations

This is a portfolio-ready foundation, not a complete healthcare production system. A production version should add HTTPS, private networking, authentication, centralized logs, detailed access controls, backup procedures, patch management, and controls required by the organization's compliance program.
