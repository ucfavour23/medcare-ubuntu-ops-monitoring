variable "aws_region" {
  description = "AWS region where the MedCare platform will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to tag AWS resources."
  type        = string
  default     = "medcare-ubuntu-ops-monitoring"
}

variable "instance_type" {
  description = "Free-tier friendly EC2 instance type."
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "Use t2.micro or t3.micro to keep this demonstration free-tier friendly where eligible."
  }
}

variable "key_name" {
  description = "Existing EC2 key pair name used for SSH access."
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to connect over SSH. Replace with your public IP/32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "http_allowed_cidr" {
  description = "CIDR allowed to view the HTTP dashboard."
  type        = string
  default     = "0.0.0.0/0"
}

variable "sns_topic_name" {
  description = "Name of the SNS topic used by CloudWatch alarms."
  type        = string
  default     = "medcare-operations-alerts"
}

variable "alert_email" {
  description = "Optional email address subscribed to alerts. Confirmation is required."
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be empty or a valid email address."
  }
}

variable "github_repository_url" {
  description = "Optional public Git repository URL. When set, user data clones and starts the dashboard."
  type        = string
  default     = ""
}
