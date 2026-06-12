# Quick Evidence Commands - Copy & Paste

## 🚀 Automated Collection (Easiest!)

### Linux/Mac:
```bash
chmod +x collect-evidence.sh
./collect-evidence.sh
```

### Windows PowerShell:
```powershell
.\collect-evidence.ps1
```

---

## 📋 Manual Commands (If script doesn't work)

### 1. EC2 Instance
```bash
aws ec2 describe-instances \
    --instance-ids $(terraform output -raw instance_id) \
    --output table > ec2-instance.txt
```

### 2. IAM Role
```bash
aws iam get-role \
    --role-name $(terraform output -raw iam_role_name) \
    --output table > iam-role.txt

aws iam list-attached-role-policies \
    --role-name $(terraform output -raw iam_role_name) \
    --output table > iam-policies.txt
```

### 3. CloudWatch Agent (On EC2)
```bash
# SSH to EC2 first
ssh -i cloudwatch-agent-lab-key.pem ec2-user@<IP>

# Then run:
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query > agent-status.json
```

### 4. CloudWatch Metrics
```bash
aws cloudwatch list-metrics \
    --namespace CWAgent \
    --output table > metrics-cwagent.txt

aws cloudwatch list-metrics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
    --output table > metrics-cpu.txt
```

### 5. CloudWatch Alarm
```bash
aws cloudwatch describe-alarms \
    --alarm-names $(terraform output -raw cloudwatch_alarm_name) \
    --output table > alarm-details.txt

aws cloudwatch describe-alarm-history \
    --alarm-name $(terraform output -raw cloudwatch_alarm_name) \
    --max-records 20 \
    --output table > alarm-history.txt
```

### 6. SNS Topic
```bash
aws sns get-topic-attributes \
    --topic-arn $(terraform output -raw sns_topic_arn) \
    --output table > sns-topic.txt

aws sns list-subscriptions-by-topic \
    --topic-arn $(terraform output -raw sns_topic_arn) \
    --output table > sns-subscriptions.txt
```

### 7. Recent CPU Data
```bash
# Linux/Mac:
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --output table > cpu-data.txt

# Windows PowerShell:
$endTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")
$startTime = (Get-Date).AddHours(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")
aws cloudwatch get-metric-statistics `
    --namespace AWS/EC2 `
    --metric-name CPUUtilization `
    --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) `
    --start-time $startTime `
    --end-time $endTime `
    --period 300 `
    --statistics Average `
    --output table > cpu-data.txt
```

### 8. All Terraform Outputs
```bash
terraform output > terraform-outputs.txt
terraform output -json > terraform-outputs.json
```

---

## 📸 Screenshot Commands

### Get URLs for AWS Console

```bash
# CloudWatch Alarms URL
echo "https://console.aws.amazon.com/cloudwatch/home?region=$(aws configure get region)#alarmsV2:"

# CloudWatch Metrics URL
echo "https://console.aws.amazon.com/cloudwatch/home?region=$(aws configure get region)#metricsV2:graph=~()"

# SNS Topics URL
echo "https://console.aws.amazon.com/sns/v3/home?region=$(aws configure get region)#/topics"

# EC2 Instances URL
echo "https://console.aws.amazon.com/ec2/home?region=$(aws configure get region)#Instances:"

# IAM Roles URL
echo "https://console.aws.amazon.com/iam/home#/roles"
```

---

## 🎯 Screenshot Checklist (Must Have!)

1. ✅ EC2 instance (running + IAM role)
2. ✅ IAM role (with CloudWatchAgentServerPolicy)
3. ✅ CloudWatch Agent status (running)
4. ✅ CloudWatch Metrics (CWAgent namespace)
5. ✅ Metrics graph (with data points)
6. ✅ CloudWatch Alarm (created)
7. ✅ Alarm configuration (threshold 80%)
8. ✅ Alarm history (OK → ALARM → OK)
9. ✅ SNS subscription (confirmed)
10. ✅ Email notification (ALARM)
11. ✅ Email notification (OK)
12. ✅ CPU test (stress running or top)

---

## 📦 Package & Submit

```bash
# Create directory
mkdir lab-evidence
mv *.txt lab-evidence/
mv *.json lab-evidence/

# Add screenshots
mkdir lab-evidence/screenshots
# Move all your .png files to screenshots/

# Create archive
tar -czf lab-evidence.tar.gz lab-evidence/
# Or Windows:
# Compress-Archive -Path lab-evidence -DestinationPath lab-evidence.zip

# Verify
tar -tzf lab-evidence.tar.gz | head -20
# Or Windows:
# Expand-Archive lab-evidence.zip -DestinationPath test/
```

---

## ✅ Final Checklist

Before submitting:
- [ ] All AWS CLI commands successful
- [ ] 12 screenshots taken
- [ ] 2 email screenshots saved
- [ ] Terraform outputs captured
- [ ] SSH agent status captured
- [ ] Archive created
- [ ] Archive verified (can extract)

---

## 🆘 Quick Fixes

### AWS CLI not working?
```bash
aws configure list
aws sts get-caller-identity
```

### Terraform output empty?
```bash
cd terraform/
terraform output
```

### Can't get instance_id?
```bash
# Find manually
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*cloudwatch*" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text
```

### Can't SSH to EC2?
```bash
chmod 400 cloudwatch-agent-lab-key.pem
ssh -v -i cloudwatch-agent-lab-key.pem ec2-user@<IP>
```

---

**Save this file for quick reference! 📌**
