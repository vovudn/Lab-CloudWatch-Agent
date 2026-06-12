# Makefile for Terraform CloudWatch Agent Lab
# Usage: make <target>

.PHONY: help init plan apply destroy fmt validate clean ssh verify test

# Default target
.DEFAULT_GOAL := help

# Variables
EMAIL ?= your-email@example.com
REGION ?= ap-southeast-1

help: ## Show this help message
	@echo "CloudWatch Agent Lab - Terraform Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make init                    # Initialize Terraform"
	@echo "  make plan EMAIL=you@example.com  # Plan with email"
	@echo "  make apply                   # Apply changes"
	@echo "  make ssh                     # SSH to EC2"
	@echo "  make destroy                 # Destroy all resources"

init: ## Initialize Terraform
	terraform init

plan: ## Show Terraform plan
	terraform plan -var="email_address=$(EMAIL)"

apply: ## Apply Terraform configuration
	terraform apply -var="email_address=$(EMAIL)"

destroy: ## Destroy all resources
	terraform destroy -var="email_address=$(EMAIL)"

fmt: ## Format Terraform files
	terraform fmt -recursive

validate: ## Validate Terraform configuration
	terraform validate

clean: ## Clean Terraform files
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f *.tfstate*
	rm -f *.pem

ssh: ## SSH to EC2 instance
	@echo "Connecting to EC2..."
	@SSH_CMD=$$(terraform output -raw ssh_command 2>/dev/null); \
	if [ -z "$$SSH_CMD" ]; then \
		echo "Error: No instance found. Run 'make apply' first."; \
		exit 1; \
	fi; \
	$$SSH_CMD

ip: ## Get EC2 public IP
	@terraform output -raw instance_public_ip 2>/dev/null || echo "No instance found"

outputs: ## Show all outputs
	@terraform output

verify: ## Verify CloudWatch Agent on EC2
	@echo "Running verification on EC2..."
	@terraform output -raw ssh_command 2>/dev/null | sh -c "$$(cat)" './verify-setup.sh'

test: ## Run CPU load test
	@echo "Running CPU load test..."
	@terraform output -raw ssh_command 2>/dev/null | sh -c "$$(cat)" './test-cpu-load.sh'

dashboard: ## Open CloudWatch Dashboard
	@URL=$$(terraform output -raw cloudwatch_dashboard_url 2>/dev/null); \
	if [ -z "$$URL" ]; then \
		echo "Error: No dashboard found."; \
		exit 1; \
	fi; \
	echo "Opening dashboard: $$URL"; \
	open "$$URL" 2>/dev/null || xdg-open "$$URL" 2>/dev/null || start "$$URL"

status: ## Show lab status
	@echo "=== CloudWatch Agent Lab Status ==="
	@echo ""
	@echo "Instance ID: $$(terraform output -raw instance_id 2>/dev/null || echo 'N/A')"
	@echo "Public IP: $$(terraform output -raw instance_public_ip 2>/dev/null || echo 'N/A')"
	@echo "SNS Topic: $$(terraform output -raw sns_topic_arn 2>/dev/null || echo 'N/A')"
	@echo "Alarm: $$(terraform output -raw cloudwatch_alarm_name 2>/dev/null || echo 'N/A')"
	@echo ""

cost: ## Estimate monthly cost
	@echo "=== Estimated Monthly Cost ==="
	@echo "EC2 t2.micro: $$0 (Free tier) or ~$$8"
	@echo "CloudWatch metrics: ~$$3"
	@echo "CloudWatch alarms: ~$$0.10"
	@echo "SNS: Free"
	@echo "Total: ~$$3-11/month"
	@echo ""
	@echo "Run 'make destroy' to avoid charges"

setup: ## Quick setup (copy tfvars and apply)
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "Created terraform.tfvars - Please edit with your email!"; \
		exit 1; \
	fi
	$(MAKE) init
	$(MAKE) apply
