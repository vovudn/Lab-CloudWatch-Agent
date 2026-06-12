# Troubleshooting Guide

## 🔍 Common Issues & Solutions

### 1. CloudWatch Agent không start được

#### Triệu chứng:
```bash
sudo systemctl status amazon-cloudwatch-agent
# Output: failed hoặc inactive
```

#### Nguyên nhân & Giải pháp:

**A. IAM Role thiếu permission**

Kiểm tra:
```bash
# Lấy metadata token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)

# Kiểm tra IAM role
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

Nếu không có output → cần attach IAM Role với `CloudWatchAgentServerPolicy`

**B. Config file sai format**

Kiểm tra:
```bash
# Validate JSON syntax
cat /opt/aws/amazon-cloudwatch-agent/bin/config.json | python3 -m json.tool

# Hoặc
jq . /opt/aws/amazon-cloudwatch-agent/bin/config.json
```

**C. Xem log chi tiết**

```bash
# Log file
sudo tail -100 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# System journal
sudo journalctl -u amazon-cloudwatch-agent -n 100 --no-pager
```

---

### 2. Metrics không hiển thị trên CloudWatch Console

#### Triệu chứng:
- CloudWatch Agent chạy OK nhưng không thấy metrics
- Namespace "CWAgent" không xuất hiện

#### Giải pháp:

**A. Kiểm tra agent status**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query
```

Expected output:
```json
{
  "status": "running",
  "starttime": "...",
  "configstatus": "configured"
}
```

**B. Kiểm tra IAM permissions**

IAM Role cần có policy: `CloudWatchAgentServerPolicy`

Policy content:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

**C. Đợi metrics xuất hiện**

Metrics có thể mất 5-10 phút để xuất hiện lần đầu. Đợi và refresh CloudWatch Console.

**D. Kiểm tra region đúng không**

Đảm bảo bạn đang xem CloudWatch Console ở đúng region với EC2 instance.

---

### 3. Alarm không trigger dù CPU cao

#### Triệu chứng:
- CPU thực tế > 80%
- Alarm vẫn ở trạng thái OK
- Không nhận email

#### Giải pháp:

**A. Kiểm tra alarm state**

Vào CloudWatch → Alarms → xem alarm state:
- `OK` → Chưa vi phạm threshold
- `ALARM` → Đã trigger (kiểm tra email)
- `INSUFFICIENT_DATA` → Chưa đủ data để đánh giá

**B. Kiểm tra metric có data không**

1. CloudWatch → Metrics → All metrics
2. Tìm metric `CPUUtilization` cho instance của bạn
3. Graph metric → xem có data không

**C. Kiểm tra alarm configuration**

Click vào alarm → tab **Details**:
- Metric: Đúng instance ID không?
- Threshold: Greater than 80
- Period: 5 minutes
- Datapoints: 1 out of 1

**D. Xem alarm history**

Tab **History** → xem các state changes và lý do

**E. Test với threshold thấp hơn**

Tạm thời edit alarm:
- Giảm threshold xuống 10%
- Đợi 5 phút
- Check alarm có trigger không

---

### 4. Không nhận được email từ SNS

#### Triệu chứng:
- Alarm ở trạng thái ALARM
- Không nhận email

#### Giải pháp:

**A. Kiểm tra subscription status**

SNS Console → Topics → chọn topic → tab Subscriptions

Status phải là: `Confirmed` (không phải `Pending confirmation`)

**B. Confirm email subscription**

1. Tìm email "AWS Notification - Subscription Confirmation"
2. Click link "Confirm subscription"
3. Nếu không có email → resend confirmation:
   ```bash
   aws sns subscribe \
       --topic-arn arn:aws:sns:region:account-id:EC2-CPU-High-Alert \
       --protocol email \
       --notification-endpoint your-email@example.com
   ```

**C. Kiểm tra spam folder**

Email từ SNS có thể vào spam. Tìm email từ `no-reply@sns.amazonaws.com`

**D. Test SNS topic trực tiếp**

```bash
aws sns publish \
    --topic-arn arn:aws:sns:ap-southeast-1:123456789012:EC2-CPU-High-Alert \
    --subject "Test Alert" \
    --message "This is a test message from SNS"
```

Nếu không nhận được → vấn đề ở email subscription

**E. Kiểm tra alarm có action SNS không**

CloudWatch Alarm → tab **Actions** → phải có SNS topic ARN

---

### 5. Agent stop sau khi reboot EC2

#### Triệu chứng:
- Sau khi reboot EC2, agent không tự động start

#### Giải pháp:

Enable agent service:
```bash
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
```

Verify:
```bash
sudo systemctl is-enabled amazon-cloudwatch-agent
# Output: enabled
```

---

### 6. CPU Load Test không làm CPU tăng

#### Triệu chứng:
- Chạy `stress` hoặc `yes` command
- CPU vẫn thấp

#### Giải pháp:

**A. Instance type quá mạnh**

T2/T3 micro có 1-2 vCPUs → dễ test hơn
T2 large có nhiều vCPUs → cần nhiều processes

**B. Tăng số processes**

```bash
# Với stress
stress --cpu $(nproc) --timeout 300s

# Với yes command (spawn nhiều processes)
for i in {1..4}; do yes > /dev/null & done

# Kill sau khi test
pkill yes
```

**C. Monitor CPU real-time**

```bash
# Terminal 1: Run stress
stress --cpu 4 --timeout 300s

# Terminal 2: Monitor
top
# Hoặc
htop
```

---

### 7. CloudWatch metrics bị delay

#### Triệu chứng:
- Metrics xuất hiện chậm 5-10 phút

#### Giải thích:

CloudWatch có độ trễ tự nhiên:
- Standard metrics (built-in EC2): 5 phút
- Detailed monitoring: 1 phút
- Custom metrics (CWAgent): 1-5 phút

**Để giảm delay:**
1. Edit `cloudwatch-config.json`:
```json
{
  "metrics_collection_interval": 60
}
```

2. Restart agent:
```bash
sudo systemctl restart amazon-cloudwatch-agent
```

---

### 8. Agent consume quá nhiều CPU/Memory

#### Triệu chứng:
- CloudWatch Agent dùng nhiều resources

#### Giải pháp:

**A. Giảm collection interval**

Edit config:
```json
{
  "metrics_collection_interval": 300
}
```

**B. Thu thập ít metrics hơn**

Chỉ thu thập metrics cần thiết:
```json
{
  "metrics_collected": {
    "cpu": { "totalcpu": false },
    "mem": {},
    "disk": {}
  }
}
```

**C. Disable log collection** (nếu không cần)

Xóa section `logs` trong config file

---

## 🔧 Useful Commands

### Agent Management
```bash
# Start/Stop/Restart
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl stop amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent

# Status
sudo systemctl status amazon-cloudwatch-agent

# Enable auto-start
sudo systemctl enable amazon-cloudwatch-agent
```

### Agent Query
```bash
# Query agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query

# Fetch config
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

### Logs
```bash
# Tail agent log
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Journalctl
sudo journalctl -u amazon-cloudwatch-agent -f

# Last 100 lines
sudo journalctl -u amazon-cloudwatch-agent -n 100
```

---

## 📞 Support Resources

- [CloudWatch Agent Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [CloudWatch Troubleshooting](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/troubleshooting-CloudWatch-Agent.html)
- [AWS Forums](https://repost.aws/)
- [AWS Support](https://console.aws.amazon.com/support/)
