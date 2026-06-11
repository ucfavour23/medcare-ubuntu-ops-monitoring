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
  default     = "0.0.0.0/0"
}

variable "alert_email" {
  description = "Email address that receives SNS alerts."
  type        = string
}

variable "app_port" {
  description = "Dashboard application port."
  type        = number
  default     = 5000
}

variable "repository_url" {
  description = "Public GitHub repository URL used by EC2 user data to install the monitoring app."
  type        = string
  default     = "https://github.com/ucfavour23/medcare-ubuntu-ops-monitoring.git"
}
