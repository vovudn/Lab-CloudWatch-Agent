# outputs.tf - Output values after terraform apply

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.cloudwatch_lab.id
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.cloudwatch_lab.public_ip
}

output "instance_public_dns" {
  description = "EC2 Instance Public DNS"
  value       = aws_instance.cloudwatch_lab.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.cloudwatch_lab.public_ip}"
}

output "private_key_file" {
  description = "Path to private key file (if created)"
  value       = var.create_new_key_pair ? "${path.module}/${var.project_name}-key.pem" : "Using existing key: ${var.key_name}"
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch Alarms"
  value       = aws_sns_topic.cpu_alarm.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch Alarm Name"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "iam_role_name" {
  description = "IAM Role Name"
  value       = aws_iam_role.ec2_cloudwatch.name
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ec2.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "setup_instructions" {
  description = "Instructions to complete lab setup"
  value       = <<-EOT
    
    ========================================
    CloudWatch Agent Lab - Setup Complete!
    ========================================
    
    1. CONFIRM EMAIL SUBSCRIPTION:
       - Check your email: ${var.email_address}
       - Look for: "AWS Notification - Subscription Confirmation"
       - Click the confirmation link
    
    2. CONNECT TO EC2:
       ${var.create_new_key_pair ? "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.cloudwatch_lab.public_ip}" : "ssh -i your-key.pem ec2-user@${aws_instance.cloudwatch_lab.public_ip}"}
    
    3. VERIFY CLOUDWATCH AGENT:
       ./verify-setup.sh
    
    4. TEST CPU ALARM:
       ./test-cpu-load.sh
       
       Wait ~5-6 minutes, then check:
       - CloudWatch Console: Alarm will turn RED
       - Your email: You'll receive alert
    
    5. VIEW DASHBOARD:
       ${aws_cloudwatch_dashboard.main.dashboard_name}
    
    6. CLEAN UP (when done):
       terraform destroy
    
    ========================================
    Resources Created:
    ========================================
    - VPC & Networking
    - EC2 Instance: ${aws_instance.cloudwatch_lab.id}
    - IAM Role: ${aws_iam_role.ec2_cloudwatch.name}
    - SNS Topic: ${aws_sns_topic.cpu_alarm.name}
    - CloudWatch Alarm: ${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}
    - CloudWatch Dashboard: ${aws_cloudwatch_dashboard.main.dashboard_name}
    
  EOT
}
