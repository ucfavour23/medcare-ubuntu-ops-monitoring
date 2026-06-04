output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.medcare.id
}

output "public_ip" {
  description = "Public IP address of the Ubuntu server."
  value       = aws_instance.medcare.public_ip
}

output "dashboard_url" {
  description = "HTTP URL for the MedCare monitoring dashboard."
  value       = "http://${aws_instance.medcare.public_ip}"
}

output "ssh_command" {
  description = "Example SSH command when a key pair is configured."
  value       = var.key_name == null ? "No key_name configured" : "ssh -i <private-key.pem> ubuntu@${aws_instance.medcare.public_ip}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN used by the CloudWatch alarm."
  value       = aws_sns_topic.operations_alerts.arn
}
