variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used for resource naming."
  type        = string
  default     = "medcare-ubuntu-ops"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "portfolio"
}

variable "instance_type" {
  description = "Low-cost EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH. Replace with your public IP /32."
  type        = string
  default     = "127.0.0.1/32"

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0)) && var.ssh_cidr != "0.0.0.0/0"
    error_message = "ssh_cidr must be a valid CIDR block and must not be 0.0.0.0/0. Use your public IP with /32."
  }
}

variable "alert_email" {
  description = "Email address that receives SNS alerts."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "app_port" {
  description = "Dashboard application port."
  type        = number
  default     = 5000

  validation {
    condition     = var.app_port >= 1024 && var.app_port <= 65535
    error_message = "app_port must be between 1024 and 65535."
  }
}

variable "dashboard_domain" {
  description = "Optional DNS name for HTTPS dashboard access. Point this domain's A record to the EC2 public IP before applying."
  type        = string
  default     = ""
}

variable "certificate_email" {
  description = "Optional email address used by Caddy/Let's Encrypt for HTTPS certificate notices."
  type        = string
  default     = ""
}

variable "public_dashboard_cidr" {
  description = "CIDR block allowed to reach the HTTPS dashboard when dashboard_domain is set."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.public_dashboard_cidr, 0))
    error_message = "public_dashboard_cidr must be a valid CIDR block."
  }
}

variable "repository_url" {
  description = "Public GitHub repository URL used by EC2 user data to install the monitoring app."
  type        = string
  default     = "https://github.com/ucfavour23/medcare-ubuntu-ops-monitoring.git"
}
