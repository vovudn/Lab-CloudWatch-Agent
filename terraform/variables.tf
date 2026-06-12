# variables.tf - Input variables for the CloudWatch Agent Lab

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "cloudwatch-agent-lab"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "email_address" {
  description = "Email address for SNS notifications"
  type        = string
  # Must be provided: terraform apply -var="email_address=your-email@example.com"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Amazon Linux 2). Leave empty for auto-lookup"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to EC2 instance. Use your public IP/32"
  type        = string
  default     = "0.0.0.0/0" # WARNING: Change this to your IP for security!
}

variable "cpu_alarm_threshold" {
  description = "CPU threshold percentage for alarm"
  type        = number
  default     = 80
}

variable "cpu_alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarm"
  type        = number
  default     = 1
}

variable "cpu_alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300 # 5 minutes
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2 (1-minute metrics)"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "SSH key pair name (must exist in AWS). Leave empty to create a new one"
  type        = string
  default     = ""
}

variable "create_new_key_pair" {
  description = "Create a new SSH key pair"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
