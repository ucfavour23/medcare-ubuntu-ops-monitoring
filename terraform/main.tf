# Use the latest Canonical Ubuntu 22.04 LTS AMI available in us-east-1.
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

resource "aws_security_group" "medcare" {
  name_prefix = "${var.project_name}-"
  description = "Allow SSH administration and HTTP dashboard access"

  ingress {
    description = "SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP monitoring dashboard"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_allowed_cidr]
  }

  egress {
    description = "Allow outbound package and container downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "medcare" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.medcare.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    repository_url = var.github_repository_url
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-server"
  }
}

resource "aws_sns_topic" "operations_alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.operations_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  alarm_description   = "Alerts when average EC2 CPU usage exceeds 80 percent for 10 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.operations_alerts.arn]
  ok_actions          = [aws_sns_topic.operations_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.medcare.id
  }

}
