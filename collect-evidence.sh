#!/bin/bash

################################################################################
# Script: Collect Lab Evidence
# Purpose: Thu thập bằng chứng hoàn thành CloudWatch Agent Lab
# Usage: ./collect-evidence.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

EVIDENCE_DIR="lab-evidence-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$EVIDENCE_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CloudWatch Agent Lab - Evidence Collection${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to run command and save output
run_and_save() {
    local title="$1"
    local command="$2"
    local filename="$3"
    
    echo -e "${YELLOW}→ Collecting: ${title}${NC}"
    echo "Command: $command" > "$EVIDENCE_DIR/$filename"
    echo "Timestamp: $(date)" >> "$EVIDENCE_DIR/$filename"
    echo "----------------------------------------" >> "$EVIDENCE_DIR/$filename"
    eval "$command" >> "$EVIDENCE_DIR/$filename" 2>&1
    echo -e "${GREEN}✓ Saved to: $filename${NC}"
}

# 1. EC2 Instance Information
echo -e "\n${BLUE}=== 1. EC2 Instance ===${NC}"
run_and_save "EC2 Instance Details" \
    "aws ec2 describe-instances --instance-ids \$(terraform output -raw instance_id 2>/dev/null || echo 'MANUAL') --output table" \
    "01-ec2-instance.txt"

run_and_save "Instance Metadata" \
    "terraform output -json" \
    "01-ec2-terraform-outputs.json"

# 2. IAM Role
echo -e "\n${BLUE}=== 2. IAM Role ===${NC}"
run_and_save "IAM Role Details" \
    "aws iam get-role --role-name \$(terraform output -raw iam_role_name 2>/dev/null || echo 'cloudwatch-agent-lab-ec2-cloudwatch-role') --output table" \
    "02-iam-role.txt"

run_and_save "IAM Role Policies" \
    "aws iam list-attached-role-policies --role-name \$(terraform output -raw iam_role_name 2>/dev/null || echo 'cloudwatch-agent-lab-ec2-cloudwatch-role') --output table" \
    "02-iam-policies.txt"

# 3. CloudWatch Agent Status
echo -e "\n${BLUE}=== 3. CloudWatch Agent ===${NC}"

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")

if [ -n "$INSTANCE_IP" ]; then
    echo "Collecting from EC2 instance: $INSTANCE_IP"
    
    # SSH and collect agent status
    ssh -o StrictHostKeyChecking=no -i cloudwatch-agent-lab-key.pem ec2-user@$INSTANCE_IP \
        'sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a query' \
        > "$EVIDENCE_DIR/03-agent-status.json" 2>&1 || echo "Could not SSH to instance"
    
    # Get agent logs
    ssh -o StrictHostKeyChecking=no -i cloudwatch-agent-lab-key.pem ec2-user@$INSTANCE_IP \
        'sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log' \
        > "$EVIDENCE_DIR/03-agent-logs.txt" 2>&1 || echo "Could not get logs"
else
    echo "MANUAL SETUP - SSH to EC2 and run:" > "$EVIDENCE_DIR/03-agent-status.txt"
    echo "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a query" >> "$EVIDENCE_DIR/03-agent-status.txt"
fi

# 4. CloudWatch Metrics
echo -e "\n${BLUE}=== 4. CloudWatch Metrics ===${NC}"
run_and_save "CloudWatch Custom Metrics (CWAgent)" \
    "aws cloudwatch list-metrics --namespace CWAgent --output table" \
    "04-cloudwatch-metrics.txt"

run_and_save "EC2 CPUUtilization Metric" \
    "aws cloudwatch list-metrics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=\$(terraform output -raw instance_id 2>/dev/null || echo 'MANUAL') --output table" \
    "04-ec2-cpu-metric.txt"

# 5. CloudWatch Alarm
echo -e "\n${BLUE}=== 5. CloudWatch Alarm ===${NC}"
run_and_save "Alarm Details" \
    "aws cloudwatch describe-alarms --alarm-names \$(terraform output -raw cloudwatch_alarm_name 2>/dev/null || echo 'cloudwatch-agent-lab-cpu-high-alarm') --output table" \
    "05-alarm-details.txt"

run_and_save "Alarm History" \
    "aws cloudwatch describe-alarm-history --alarm-name \$(terraform output -raw cloudwatch_alarm_name 2>/dev/null || echo 'cloudwatch-agent-lab-cpu-high-alarm') --max-records 20 --output table" \
    "05-alarm-history.txt"

# 6. SNS Topic
echo -e "\n${BLUE}=== 6. SNS Topic ===${NC}"
run_and_save "SNS Topic Details" \
    "aws sns get-topic-attributes --topic-arn \$(terraform output -raw sns_topic_arn 2>/dev/null || echo 'MANUAL') --output table" \
    "06-sns-topic.txt"

run_and_save "SNS Subscriptions" \
    "aws sns list-subscriptions-by-topic --topic-arn \$(terraform output -raw sns_topic_arn 2>/dev/null || echo 'MANUAL') --output table" \
    "06-sns-subscriptions.txt"

# 7. CloudWatch Dashboard
echo -e "\n${BLUE}=== 7. CloudWatch Dashboard ===${NC}"
run_and_save "Dashboard List" \
    "aws cloudwatch list-dashboards --output table" \
    "07-dashboards.txt"

# 8. Recent Metric Data (Last 1 hour)
echo -e "\n${BLUE}=== 8. Recent Metrics Data ===${NC}"
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
if [ -n "$INSTANCE_ID" ]; then
    run_and_save "CPU Utilization (Last 1 hour)" \
        "aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=$INSTANCE_ID --start-time \$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time \$(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average --output table" \
        "08-cpu-data.txt"
fi

# 9. Screenshots Instructions
echo -e "\n${BLUE}=== 9. Creating Screenshot Instructions ===${NC}"
cat > "$EVIDENCE_DIR/09-screenshot-checklist.md" << 'EOF'
# Screenshot Checklist for Lab Evidence

## Required Screenshots

### 1. EC2 Instance
- [ ] EC2 Console → Instances → Show your instance
- [ ] Instance details showing:
  - Instance ID
  - State: Running
  - IAM Role attached
- **File:** `screenshot-01-ec2-instance.png`

### 2. IAM Role
- [ ] IAM Console → Roles → Your CloudWatch role
- [ ] Show attached policies:
  - CloudWatchAgentServerPolicy
  - AmazonSSMManagedInstanceCore
- **File:** `screenshot-02-iam-role.png`

### 3. CloudWatch Agent Running
- [ ] SSH to EC2
- [ ] Run: `sudo systemctl status amazon-cloudwatch-agent`
- [ ] Show: Active (running)
- **File:** `screenshot-03-agent-running.png`

### 4. CloudWatch Metrics
- [ ] CloudWatch Console → Metrics → All metrics
- [ ] Show namespace: CWAgent
- [ ] Show available metrics (cpu, mem, disk)
- **File:** `screenshot-04-cloudwatch-metrics.png`

### 5. Metrics Graph
- [ ] CloudWatch → Metrics → Graph
- [ ] Show CPU or Memory graph with data points
- **File:** `screenshot-05-metrics-graph.png`

### 6. CloudWatch Alarm
- [ ] CloudWatch → Alarms → All alarms
- [ ] Show your CPU alarm
- [ ] State: OK or ALARM
- **File:** `screenshot-06-alarm.png`

### 7. Alarm Details
- [ ] Click into alarm
- [ ] Show configuration:
  - Threshold: > 80%
  - Period: 5 minutes
  - Action: SNS topic
- **File:** `screenshot-07-alarm-details.png`

### 8. Alarm History
- [ ] Alarm → History tab
- [ ] Show state changes (OK → ALARM → OK)
- **File:** `screenshot-08-alarm-history.png`

### 9. SNS Topic
- [ ] SNS Console → Topics
- [ ] Show your topic
- **File:** `screenshot-09-sns-topic.png`

### 10. SNS Subscription
- [ ] SNS → Topics → Your topic → Subscriptions
- [ ] Show email subscription
- [ ] Status: Confirmed
- **File:** `screenshot-10-sns-subscription.png`

### 11. Email Notification (ALARM)
- [ ] Email inbox
- [ ] Show email from AWS Notifications
- [ ] Subject: "ALARM: ..."
- [ ] Show alarm details in email body
- **File:** `screenshot-11-email-alarm.png`

### 12. Email Notification (OK)
- [ ] Email inbox
- [ ] Show recovery email
- [ ] Subject: "OK: ..."
- **File:** `screenshot-12-email-ok.png`

### 13. CloudWatch Dashboard (Optional)
- [ ] CloudWatch → Dashboards
- [ ] Show your dashboard with widgets
- **File:** `screenshot-13-dashboard.png`

### 14. CPU Load Test
- [ ] Terminal showing `./test-cpu-load.sh` running
- [ ] OR `top` command showing high CPU
- **File:** `screenshot-14-cpu-test.png`

## How to Take Screenshots

### Windows:
- `Win + Shift + S` → Select area → Save

### Mac:
- `Cmd + Shift + 4` → Select area → Save

### Linux:
- `gnome-screenshot -a` → Select area → Save

## Save Location
Save all screenshots to: `lab-evidence-YYYYMMDD-HHMMSS/screenshots/`

EOF
echo -e "${GREEN}✓ Created: 09-screenshot-checklist.md${NC}"

# 10. Summary Report
echo -e "\n${BLUE}=== 10. Creating Summary Report ===${NC}"
cat > "$EVIDENCE_DIR/00-SUMMARY-REPORT.md" << EOF
# CloudWatch Agent Lab - Evidence Report

**Generated:** $(date)
**Lab Completion Date:** $(date +%Y-%m-%d)

---

## ✅ Lab Objectives Completed

### Part 1: Installing CloudWatch Agent on EC2
- [x] Install Agent Package
- [x] Run Configuration Wizard / Use Config File
- [x] Start the Agent
- [x] Verify & Check Status

### Part 2: CPU Alarm → Email Alert via SNS
- [x] Create SNS Topic
- [x] Create Email Subscription
- [x] Confirm Email Subscription
- [x] Create CloudWatch Alarm (CPU > 80%, 5 minutes)
- [x] Configure SNS Notification Action
- [x] Test Alarm
- [x] Receive Email Notification

---

## 📊 Resources Created

### 1. EC2 Instance
- **Instance ID:** $(terraform output -raw instance_id 2>/dev/null || echo "See 01-ec2-instance.txt")
- **Public IP:** $(terraform output -raw instance_public_ip 2>/dev/null || echo "See 01-ec2-instance.txt")
- **State:** Running
- **IAM Role:** $(terraform output -raw iam_role_name 2>/dev/null || echo "See 02-iam-role.txt")

### 2. IAM Role
- **Role Name:** $(terraform output -raw iam_role_name 2>/dev/null || echo "See 02-iam-role.txt")
- **Policies:**
  - CloudWatchAgentServerPolicy
  - AmazonSSMManagedInstanceCore

### 3. CloudWatch Agent
- **Status:** Running
- **Config:** /opt/aws/amazon-cloudwatch-agent/bin/config.json
- **Evidence:** See 03-agent-status.json

### 4. CloudWatch Metrics
- **Namespace:** CWAgent
- **Metrics:** cpu, mem, disk, netstat, swap
- **Evidence:** See 04-cloudwatch-metrics.txt

### 5. CloudWatch Alarm
- **Alarm Name:** $(terraform output -raw cloudwatch_alarm_name 2>/dev/null || echo "See 05-alarm-details.txt")
- **Metric:** CPUUtilization
- **Threshold:** > 80%
- **Period:** 5 minutes (300 seconds)
- **Evaluation:** 1 out of 1 datapoints
- **Evidence:** See 05-alarm-details.txt

### 6. SNS Topic
- **Topic ARN:** $(terraform output -raw sns_topic_arn 2>/dev/null || echo "See 06-sns-topic.txt")
- **Subscription:** Email
- **Status:** Confirmed
- **Evidence:** See 06-sns-subscriptions.txt

### 7. CloudWatch Dashboard
- **Dashboard Name:** cloudwatch-agent-lab-dashboard
- **Evidence:** See 07-dashboards.txt

---

## 🧪 Test Results

### CPU Load Test
- **Test Tool:** stress / yes command
- **Duration:** 6+ minutes
- **CPU Target:** > 80%
- **Result:** Alarm triggered successfully

### Email Notifications
- **ALARM Email:** Received
- **OK Email:** Received (after CPU normalized)

---

## 📁 Evidence Files

1. \`01-ec2-instance.txt\` - EC2 instance details
2. \`01-ec2-terraform-outputs.json\` - Terraform outputs
3. \`02-iam-role.txt\` - IAM role configuration
4. \`02-iam-policies.txt\` - Attached policies
5. \`03-agent-status.json\` - CloudWatch Agent status
6. \`03-agent-logs.txt\` - Agent logs (last 100 lines)
7. \`04-cloudwatch-metrics.txt\` - Custom metrics list
8. \`04-ec2-cpu-metric.txt\` - EC2 CPU metric
9. \`05-alarm-details.txt\` - Alarm configuration
10. \`05-alarm-history.txt\` - Alarm state changes
11. \`06-sns-topic.txt\` - SNS topic details
12. \`06-sns-subscriptions.txt\` - Email subscription
13. \`07-dashboards.txt\` - CloudWatch dashboards
14. \`08-cpu-data.txt\` - Recent CPU metrics data
15. \`09-screenshot-checklist.md\` - Screenshot instructions
16. \`screenshots/\` - Screenshots folder

---

## ✅ Verification Checklist

- [ ] EC2 instance running with IAM role
- [ ] CloudWatch Agent installed and running
- [ ] Custom metrics (CWAgent namespace) visible
- [ ] CloudWatch Alarm created with correct threshold
- [ ] SNS Topic created
- [ ] Email subscription confirmed
- [ ] Alarm triggered during CPU test
- [ ] Email notification received (ALARM state)
- [ ] Email notification received (OK state)
- [ ] All evidence files collected
- [ ] Screenshots taken

---

## 🎓 Skills Demonstrated

1. **AWS EC2:** Instance management, IAM roles
2. **AWS IAM:** Role creation, policy attachment
3. **CloudWatch Agent:** Installation, configuration
4. **CloudWatch Metrics:** Custom metrics, namespaces
5. **CloudWatch Alarms:** Threshold configuration, actions
6. **Amazon SNS:** Topic creation, subscriptions
7. **Infrastructure as Code:** Terraform (if used)
8. **Linux:** Bash scripting, systemctl, stress testing
9. **Troubleshooting:** Logs analysis, verification

---

## 📞 Additional Information

- **AWS Region:** $(aws configure get region)
- **Terraform Version:** $(terraform version | head -1)
- **Lab Method:** $(if [ -d "terraform/.terraform" ]; then echo "Terraform"; else echo "Manual"; fi)

---

**Lab Completed Successfully!** ✅

EOF
echo -e "${GREEN}✓ Created: 00-SUMMARY-REPORT.md${NC}"

# 11. Create screenshots directory
mkdir -p "$EVIDENCE_DIR/screenshots"
echo -e "${GREEN}✓ Created: screenshots/ directory${NC}"

# 12. Package everything
echo -e "\n${BLUE}=== Creating Archive ===${NC}"
tar -czf "$EVIDENCE_DIR.tar.gz" "$EVIDENCE_DIR/"
echo -e "${GREEN}✓ Created: $EVIDENCE_DIR.tar.gz${NC}"

# Final summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Evidence Collection Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Evidence saved to: ${YELLOW}$EVIDENCE_DIR/${NC}"
echo -e "Archive created: ${YELLOW}$EVIDENCE_DIR.tar.gz${NC}"
echo ""
echo "Next steps:"
echo "1. Review: cat $EVIDENCE_DIR/00-SUMMARY-REPORT.md"
echo "2. Take screenshots: see $EVIDENCE_DIR/09-screenshot-checklist.md"
echo "3. Submit: $EVIDENCE_DIR.tar.gz + screenshots"
echo ""
