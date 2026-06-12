# Terraform Infrastructure for CloudWatch Agent Lab

## 📋 Overview

This Terraform configuration automatically provisions the complete infrastructure for the CloudWatch Agent lab:

- ✅ VPC with public subnet and Internet Gateway
- ✅ EC2 instance (Amazon Linux 2)
- ✅ IAM Role with CloudWatchAgentServerPolicy
- ✅ CloudWatch Agent pre-installed and configured
- ✅ SNS Topic with email subscription
- ✅ CloudWatch Alarm (CPU > 80% for 5 minutes)
- ✅ CloudWatch Dashboard
- ✅ Security Group with SSH access

---

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Key, and Region
   ```

2. **Terraform installed:**
   ```bash
   # Download from: https://www.terraform.io/downloads
   terraform version  # Should be >= 1.0
   ```

3. **Your email address** for SNS notifications

---

### Step 1: Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars  # Windows
# OR
vim terraform.tfvars      # Linux/Mac
```

**Required changes:**
```hcl
email_address    = "your-email@example.com"  # REQUIRED
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"       # IMPORTANT for security!
```

Get your public IP:
```bash
curl ifconfig.me
```

---

### Step 2: Initialize Terraform

```bash
cd terraform/
terraform init
```

---

### Step 3: Review Plan

```bash
terraform plan
```

Review the resources that will be created.

---

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time:** ~3-5 minutes

---

### Step 5: Confirm Email Subscription

After `terraform apply` completes:

1. **Check your email inbox**
2. Look for: `AWS Notification - Subscription Confirmation`
3. **Click the confirmation link**

---

### Step 6: Connect to EC2

```bash
# SSH command is in terraform output
terraform output -raw ssh_command

# Or manually:
ssh -i cloudwatch-agent-lab-key.pem ec2-user@<PUBLIC_IP>
```

---

### Step 7: Verify Setup

```bash
# Once connected to EC2:
./verify-setup.sh
```

Expected output:
```
✓ CloudWatch Agent is running
✓ Config file exists
✓ Metrics being sent to CloudWatch
```

---

### Step 8: Test Alarm

```bash
# On EC2 instance:
./test-cpu-load.sh
```

**What happens:**
1. CPU load increases to >80%
2. After ~5 minutes: CloudWatch Alarm triggers
3. You receive email notification
4. Alarm turns RED in AWS Console

---

## 📊 View Resources

### CloudWatch Dashboard

```bash
# Get dashboard URL
terraform output cloudwatch_dashboard_url
```

### CloudWatch Alarms

AWS Console → CloudWatch → Alarms

### SNS Topic

```bash
terraform output sns_topic_arn
```

---

## 🧹 Clean Up

**IMPORTANT:** Destroy resources when done to avoid costs!

```bash
terraform destroy
```

Type `yes` to confirm.

---

## 📁 File Structure

```
terraform/
├── main.tf                    # Main config & providers
├── variables.tf               # Input variables
├── terraform.tfvars.example   # Example values
├── terraform.tfvars          # Your values (create this)
├── outputs.tf                 # Output values
├── network.tf                 # VPC, subnets, security groups
├── iam.tf                     # IAM roles & policies
├── ec2.tf                     # EC2 instance
├── cloudwatch.tf              # CloudWatch alarms & dashboard
├── sns.tf                     # SNS topic & subscription
├── user-data.sh               # EC2 bootstrap script
└── README.md                  # This file
```

---

## ⚙️ Configuration Options

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `email_address` | Email for SNS alerts | **REQUIRED** |
| `aws_region` | AWS region | `ap-southeast-1` |
| `instance_type` | EC2 instance type | `t2.micro` |
| `cpu_alarm_threshold` | CPU % for alarm | `80` |
| `cpu_alarm_period` | Alarm evaluation period (sec) | `300` (5 min) |
| `allowed_ssh_cidr` | CIDR for SSH access | `0.0.0.0/0` ⚠️ |
| `create_new_key_pair` | Create new SSH key | `true` |

### Customize Alarm

Edit `terraform.tfvars`:
```hcl
cpu_alarm_threshold          = 70  # Alert at 70% instead
cpu_alarm_evaluation_periods = 2   # Require 2 consecutive periods
cpu_alarm_period             = 180 # 3 minutes per period
```

---

## 💰 Cost Estimate

**Running 24/7:**
- EC2 t2.micro: Free tier or ~$8/month
- CloudWatch metrics: ~$3/month
- CloudWatch alarms: ~$0.10/month
- SNS: Free (< 1000 emails)

**Total:** ~$0-11/month (depending on free tier)

**After `terraform destroy`:** $0

---

## 🔍 Troubleshooting

### Issue: Email not received

**Solution:**
- Check spam folder
- Verify email in `terraform.tfvars`
- Check SNS subscription status:
  ```bash
  aws sns list-subscriptions-by-topic \
      --topic-arn $(terraform output -raw sns_topic_arn)
  ```

### Issue: Cannot SSH to instance

**Solution:**
- Check security group allows your IP:
  ```bash
  terraform output security_group_id
  ```
- Verify key permissions:
  ```bash
  chmod 400 cloudwatch-agent-lab-key.pem
  ```
- Wait 2-3 minutes after `terraform apply`

### Issue: CloudWatch Agent not running

**Solution:**
```bash
# SSH to EC2
ssh -i cloudwatch-agent-lab-key.pem ec2-user@<IP>

# Check logs
sudo tail -50 /var/log/cloud-init-output.log
sudo journalctl -u amazon-cloudwatch-agent -n 50
```

### Issue: Alarm not triggering

**Solution:**
- Verify CPU is actually >80%: run `top`
- Check alarm status in AWS Console
- Wait full 5 minutes after CPU spike

---

## 📚 Terraform Commands Reference

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Show plan
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show outputs
terraform output

# Show specific output
terraform output -raw instance_public_ip

# Show state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import aws_instance.cloudwatch_lab i-xxxxx
```

---

## 🔐 Security Best Practices

### 1. SSH Access

❌ **Bad:**
```hcl
allowed_ssh_cidr = "0.0.0.0/0"  # Open to the world!
```

✅ **Good:**
```hcl
allowed_ssh_cidr = "203.123.45.67/32"  # Your IP only
```

### 2. SSH Key

```bash
# Set proper permissions
chmod 400 cloudwatch-agent-lab-key.pem

# Never commit to Git
echo "*.pem" >> .gitignore
```

### 3. Terraform State

Terraform state contains sensitive data. Options:

**Option A: Remote Backend (Recommended)**
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "cloudwatch-lab/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
```

**Option B: Encrypt Local State**
```bash
# Add to .gitignore
echo "*.tfstate*" >> .gitignore
```

---

## 🎓 Learning Resources

### Terraform Docs
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Language](https://www.terraform.io/language)

### AWS Docs
- [CloudWatch Agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)

---

## 📝 Next Steps

After completing this lab:

1. **Modify the alarm:**
   - Add memory threshold alarm
   - Add disk space alarm
   
2. **Add more metrics:**
   - Edit `cloudwatch-config.json`
   - Update `user-data.sh`
   - Run `terraform apply`

3. **Multi-instance:**
   - Use `count` or `for_each`
   - Deploy to multiple AZs

4. **Advanced:**
   - Add Auto Scaling
   - Add Lambda auto-remediation
   - Add CloudWatch Logs

---

**🎉 Enjoy your automated CloudWatch Agent lab!**

For issues, refer to:
- Main lab docs: `../README.md`
- Troubleshooting: `../docs/TROUBLESHOOTING.md`
- FAQ: `../docs/FAQ.md`
