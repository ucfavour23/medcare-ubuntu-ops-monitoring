data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "ec2_monitoring" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_monitoring" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.ec2_monitoring.name
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "MedCare Ubuntu monitoring access"

  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  description       = "SSH administration"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_cidr]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "dashboard_direct" {
  count             = var.dashboard_domain == "" ? 1 : 0
  type              = "ingress"
  description       = "Direct HTTP dashboard for temporary IP-based demos"
  from_port         = var.app_port
  to_port           = var.app_port
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_cidr]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_instance" "ubuntu_ops" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_monitoring.name
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user_data.sh", {
    project_name      = var.project_name
    app_port          = var.app_port
    aws_region        = var.aws_region
    repository_url    = var.repository_url
    dashboard_domain  = var.dashboard_domain
    certificate_email = var.certificate_email
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ubuntu-server"
  }
}

resource "aws_security_group_rule" "dashboard_http" {
  count             = var.dashboard_domain == "" ? 0 : 1
  type              = "ingress"
  description       = "HTTP challenge and redirect for HTTPS dashboard"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.public_dashboard_cidr]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "dashboard_https" {
  count             = var.dashboard_domain == "" ? 0 : 1
  type              = "ingress"
  description       = "HTTPS dashboard"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.public_dashboard_cidr]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  alarm_description   = "CPU utilization is above 80 percent for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.ubuntu_ops.id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-status-check-failed"
  alarm_description   = "EC2 instance status checks are failing."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.ubuntu_ops.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_disk" {
  alarm_name          = "${var.project_name}-${var.environment}-high-disk"
  alarm_description   = "Root filesystem disk usage is above 80 percent."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.ubuntu_ops.id
    path       = "/"
    fstype     = "ext4"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  alarm_description   = "Memory usage is above 85 percent."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.ubuntu_ops.id
  }
}
