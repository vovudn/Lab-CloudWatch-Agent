# PowerShell script for Windows users
# CloudWatch Agent Lab - Evidence Collection

$ErrorActionPreference = "Continue"

# Create evidence directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$evidenceDir = "lab-evidence-$timestamp"
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
New-Item -ItemType Directory -Path "$evidenceDir\screenshots" -Force | Out-Null

Write-Host "`n========================================" -ForegroundColor Blue
Write-Host "  CloudWatch Agent Lab - Evidence Collection" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

# Function to run command and save output
function Save-Evidence {
    param(
        [string]$Title,
        [string]$Command,
        [string]$Filename
    )
    
    Write-Host "-> Collecting: $Title" -ForegroundColor Yellow
    
    $output = @"
Command: $Command
Timestamp: $(Get-Date)
----------------------------------------

"@
    
    try {
        $result = Invoke-Expression $Command 2>&1 | Out-String
        $output += $result
    }
    catch {
        $output += "Error: $_"
    }
    
    $output | Out-File -FilePath "$evidenceDir\$Filename" -Encoding UTF8
    Write-Host "  Saved to: $Filename" -ForegroundColor Green
}

# Get Terraform outputs
Write-Host "`n=== Getting Terraform Outputs ===" -ForegroundColor Blue
$tfOutputs = @{}
try {
    Push-Location terraform
    $tfJson = terraform output -json | ConvertFrom-Json
    foreach ($key in $tfJson.PSObject.Properties.Name) {
        $tfOutputs[$key] = $tfJson.$key.value
    }
    Pop-Location
    Write-Host "  Terraform outputs loaded" -ForegroundColor Green
}
catch {
    Write-Host "  Terraform not found or not applied" -ForegroundColor Yellow
    Pop-Location
}

# 1. EC2 Instance
Write-Host "`n=== 1. EC2 Instance ===" -ForegroundColor Blue
if ($tfOutputs.instance_id) {
    Save-Evidence "EC2 Instance Details" `
        "aws ec2 describe-instances --instance-ids $($tfOutputs.instance_id) --output table" `
        "01-ec2-instance.txt"
}

Save-Evidence "Terraform Outputs" `
    "terraform output -json" `
    "01-terraform-outputs.json"

# 2. IAM Role
Write-Host "`n=== 2. IAM Role ===" -ForegroundColor Blue
if ($tfOutputs.iam_role_name) {
    Save-Evidence "IAM Role Details" `
        "aws iam get-role --role-name $($tfOutputs.iam_role_name) --output table" `
        "02-iam-role.txt"
    
    Save-Evidence "IAM Policies" `
        "aws iam list-attached-role-policies --role-name $($tfOutputs.iam_role_name) --output table" `
        "02-iam-policies.txt"
}

# 3. CloudWatch Metrics
Write-Host "`n=== 3. CloudWatch Metrics ===" -ForegroundColor Blue
Save-Evidence "Custom Metrics (CWAgent)" `
    "aws cloudwatch list-metrics --namespace CWAgent --output table" `
    "03-cloudwatch-metrics.txt"

if ($tfOutputs.instance_id) {
    Save-Evidence "EC2 CPU Metric" `
        "aws cloudwatch list-metrics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=$($tfOutputs.instance_id) --output table" `
        "03-ec2-cpu-metric.txt"
}

# 4. CloudWatch Alarm
Write-Host "`n=== 4. CloudWatch Alarm ===" -ForegroundColor Blue
if ($tfOutputs.cloudwatch_alarm_name) {
    Save-Evidence "Alarm Details" `
        "aws cloudwatch describe-alarms --alarm-names $($tfOutputs.cloudwatch_alarm_name) --output table" `
        "04-alarm-details.txt"
    
    Save-Evidence "Alarm History" `
        "aws cloudwatch describe-alarm-history --alarm-name $($tfOutputs.cloudwatch_alarm_name) --max-records 20 --output table" `
        "04-alarm-history.txt"
}

# 5. SNS Topic
Write-Host "`n=== 5. SNS Topic ===" -ForegroundColor Blue
if ($tfOutputs.sns_topic_arn) {
    Save-Evidence "SNS Topic Attributes" `
        "aws sns get-topic-attributes --topic-arn $($tfOutputs.sns_topic_arn) --output table" `
        "05-sns-topic.txt"
    
    Save-Evidence "SNS Subscriptions" `
        "aws sns list-subscriptions-by-topic --topic-arn $($tfOutputs.sns_topic_arn) --output table" `
        "05-sns-subscriptions.txt"
}

# 6. Dashboard
Write-Host "`n=== 6. CloudWatch Dashboard ===" -ForegroundColor Blue
Save-Evidence "Dashboard List" `
    "aws cloudwatch list-dashboards --output table" `
    "06-dashboards.txt"

# 7. Create Summary Report
Write-Host "`n=== 7. Creating Summary Report ===" -ForegroundColor Blue
$summaryReport = @"
# CloudWatch Agent Lab - Evidence Report

**Generated:** $(Get-Date)
**Lab Completion Date:** $(Get-Date -Format "yyyy-MM-dd")

---

## Resources Created

### EC2 Instance
- **Instance ID:** $($tfOutputs.instance_id)
- **Public IP:** $($tfOutputs.instance_public_ip)
- **IAM Role:** $($tfOutputs.iam_role_name)

### CloudWatch Alarm
- **Alarm Name:** $($tfOutputs.cloudwatch_alarm_name)
- **Threshold:** > 80%
- **Period:** 5 minutes

### SNS Topic
- **Topic ARN:** $($tfOutputs.sns_topic_arn)

---

## Evidence Files Collected

1. 01-ec2-instance.txt
2. 01-terraform-outputs.json
3. 02-iam-role.txt
4. 02-iam-policies.txt
5. 03-cloudwatch-metrics.txt
6. 03-ec2-cpu-metric.txt
7. 04-alarm-details.txt
8. 04-alarm-history.txt
9. 05-sns-topic.txt
10. 05-sns-subscriptions.txt
11. 06-dashboards.txt

---

## Next Steps

1. Review all .txt files in this directory
2. Take screenshots (see screenshot-checklist.md)
3. Save email notifications
4. Create archive for submission

---

**Lab Completed Successfully!**

"@

$summaryReport | Out-File -FilePath "$evidenceDir\00-SUMMARY-REPORT.md" -Encoding UTF8
Write-Host "  Created: 00-SUMMARY-REPORT.md" -ForegroundColor Green

# 8. Screenshot Checklist
$screenshotChecklist = Get-Content "EVIDENCE-GUIDE.md" -Raw
$screenshotChecklist | Out-File -FilePath "$evidenceDir\screenshot-checklist.md" -Encoding UTF8
Write-Host "  Created: screenshot-checklist.md" -ForegroundColor Green

# 9. Create Archive
Write-Host "`n=== Creating Archive ===" -ForegroundColor Blue
Compress-Archive -Path $evidenceDir -DestinationPath "$evidenceDir.zip" -Force
Write-Host "  Created: $evidenceDir.zip" -ForegroundColor Green

# Final Summary
Write-Host "`n========================================" -ForegroundColor Blue
Write-Host "  Evidence Collection Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Blue

Write-Host "Evidence saved to: " -NoNewline
Write-Host "$evidenceDir\" -ForegroundColor Yellow
Write-Host "Archive created: " -NoNewline
Write-Host "$evidenceDir.zip`n" -ForegroundColor Yellow

Write-Host "Next steps:"
Write-Host "1. Review: type $evidenceDir\00-SUMMARY-REPORT.md"
Write-Host "2. Take screenshots: see $evidenceDir\screenshot-checklist.md"
Write-Host "3. Submit: $evidenceDir.zip + screenshots`n"
