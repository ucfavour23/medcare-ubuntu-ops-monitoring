output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.ubuntu_ops.id
}

output "public_ip" {
  description = "Public IP address of the Ubuntu server."
  value       = aws_instance.ubuntu_ops.public_ip
}

output "ssh_command" {
  description = "SSH command if key_name was provided."
  value       = var.key_name == null ? "Use AWS Systems Manager Session Manager or set key_name." : "ssh -i <your-key.pem> ubuntu@${aws_instance.ubuntu_ops.public_ip}"
}

output "dashboard_url" {
  description = "Monitoring dashboard URL."
  value       = var.dashboard_domain == "" ? "http://${aws_instance.ubuntu_ops.public_ip}:${var.app_port}" : "https://${var.dashboard_domain}"
}

output "sns_topic_arn" {
  description = "SNS topic used by alarms."
  value       = aws_sns_topic.alerts.arn
}
