# Lab: Installing CloudWatch Agent on EC2 & CPU Alarm Alert via SNS

## 📋 Mục tiêu Lab

Lab này hướng dẫn bạn:
1. Cài đặt và cấu hình CloudWatch Agent trên EC2 instance
2. Thu thập metrics từ EC2 instance
3. Tạo CloudWatch Alarm để cảnh báo khi CPU > 80% trong 5 phút liên tiếp
4. Gửi email thông báo qua Amazon SNS

## 🎯 Yêu cầu trước khi bắt đầu

### AWS Resources cần có:
- [x] EC2 instance đang chạy (Amazon Linux 2, Ubuntu, hoặc RHEL)
- [x] IAM Role có policy `CloudWatchAgentServerPolicy` attached vào EC2
- [x] Security Group cho phép SSH (port 22)
- [x] Email để nhận thông báo

### Kiến thức yêu cầu:
- Cơ bản về AWS EC2, IAM, CloudWatch, SNS
- Sử dụng SSH và command line cơ bản

## 📚 Nội dung Lab

---

## PHẦN 1: Cài đặt CloudWatch Agent trên EC2

### Bước 1: Kiểm tra IAM Role

Trước khi bắt đầu, đảm bảo EC2 instance của bạn có IAM Role với policy `CloudWatchAgentServerPolicy`.

**Cách kiểm tra:**
1. Vào EC2 Console → chọn instance của bạn
2. Tab **Security** → xem **IAM Role**
3. Click vào IAM Role → xem **Permissions policies**
4. Đảm bảo có policy: `CloudWatchAgentServerPolicy`

**Nếu chưa có, tạo IAM Role:**
```bash
# Bạn có thể dùng script tự động (xem thư mục setup-scripts/)
# Hoặc tạo thủ công qua IAM Console
```

### Bước 2: Kết nối SSH vào EC2

```bash
ssh -i your-key.pem ec2-user@your-ec2-public-ip

# Hoặc với Ubuntu:
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### Bước 3: Cài đặt CloudWatch Agent Package

**Cho Amazon Linux 2 / RHEL:**
```bash
sudo yum install amazon-cloudwatch-agent -y
```

**Cho Ubuntu / Debian:**
```bash
sudo apt-get update
sudo apt-get install amazon-cloudwatch-agent -y
```

**Xác nhận cài đặt thành công:**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a query
```

### Bước 4: Chạy Configuration Wizard

CloudWatch Agent cung cấp wizard để tạo file cấu hình:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

**Các lựa chọn quan trọng trong wizard:**

1. **On which OS are you planning to use the agent?**
   - Chọn: `1. linux`

2. **Are you using EC2 or On-Premises hosts?**
   - Chọn: `1. EC2`

3. **Which user are you planning to run the agent?**
   - Chọn: `1. root`

4. **Do you want to turn on StatsD daemon?**
   - Chọn: `2. no`

5. **Do you want to monitor metrics from CollectD?**
   - Chọn: `2. no`

6. **Do you want to monitor any host metrics?**
   - Chọn: `1. yes`

7. **Do you want to monitor cpu metrics per core?**
   - Chọn: `2. no` (để giảm chi phí)

8. **Do you want to add ec2 dimensions?**
   - Chọn: `1. yes`

9. **Do you want to aggregate ec2 dimensions?**
   - Chọn: `1. yes` (Instance ID)

10. **Do you want to monitor any customized log files?**
    - Chọn: `2. no` (cho lab đơn giản)

11. **Do you want to store the config in SSM parameter store?**
    - Chọn: `2. no`

**File cấu hình sẽ được lưu tại:**
```
/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

### Bước 5: Start CloudWatch Agent

```bash
# Enable agent để tự động start khi reboot
sudo systemctl enable amazon-cloudwatch-agent

# Start agent
sudo systemctl start amazon-cloudwatch-agent
```

### Bước 6: Verify & Check Status

```bash
# Kiểm tra status của agent
sudo systemctl status amazon-cloudwatch-agent

# Hoặc dùng command:
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query
```

**Kết quả mong đợi:**
```json
{
  "status": "running",
  "starttime": "2024-xx-xx...",
  "configstatus": "configured",
  "version": "x.x.x"
}
```

### Bước 7: Xem logs (nếu có lỗi)

```bash
# Xem log file
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Xem log chi tiết
sudo journalctl -u amazon-cloudwatch-agent -f
```

---

## PHẦN 2: Tạo CPU Alarm với Email Alert qua SNS

### Scenario
**Gửi email cảnh báo khi EC2 CPU > 80% trong 5 phút liên tiếp**

---

### Bước 1: Tạo SNS Topic & Email Subscription

#### 1.1. Tạo SNS Topic

1. Vào **AWS Console** → **SNS** (Simple Notification Service)
2. Click **Topics** → **Create topic**
3. Chọn **Type**: `Standard`
4. **Name**: `EC2-CPU-High-Alert`
5. **Display name**: `CPU Alert` (tùy chọn)
6. Click **Create topic**

**Lưu lại SNS Topic ARN**, ví dụ:
```
arn:aws:sns:ap-southeast-1:123456789012:EC2-CPU-High-Alert
```

#### 1.2. Thêm Email Subscription

1. Trong topic vừa tạo → Tab **Subscriptions**
2. Click **Create subscription**
3. **Protocol**: `Email`
4. **Endpoint**: Nhập email của bạn (ví dụ: `your-email@example.com`)
5. Click **Create subscription**

#### 1.3. Confirm Email Subscription

1. Kiểm tra email inbox của bạn
2. Mở email từ **AWS Notifications**
3. Click link **Confirm subscription**
4. Trạng thái subscription sẽ chuyển từ `Pending confirmation` → `Confirmed`

---

### Bước 2: Tạo CloudWatch Alarm

#### 2.1. Navigate to CloudWatch

1. Vào **AWS Console** → **CloudWatch**
2. Menu bên trái → **Alarms** → **All alarms**
3. Click **Create alarm**

#### 2.2. Select Metric

1. Click **Select metric**
2. Chọn **EC2** → **Per-Instance Metrics**
3. Tìm instance ID của bạn
4. Chọn metric: **CPUUtilization**
5. Click **Select metric**

#### 2.3. Configure Alarm Conditions

**Specify metric and conditions:**

| Field | Value |
|-------|-------|
| **Statistic** | Average |
| **Period** | 5 minutes |
| **Threshold type** | Static |
| **Whenever CPUUtilization is...** | Greater than 80 |
| **Datapoints to alarm** | 1 out of 1 |

**Giải thích:**
- **Period: 5 minutes** → Đánh giá mỗi 5 phút
- **Greater than 80** → Ngưỡng cảnh báo 80%
- **1 out of 1 datapoints** → Kích hoạt alarm ngay sau 1 lần vi phạm (5 phút đầu tiên)

Click **Next**

#### 2.4. Configure Actions

**Notification:**
1. **Alarm state trigger**: `In alarm`
2. **Send a notification to**: Chọn SNS topic `EC2-CPU-High-Alert`
3. **Optional**: Thêm **OK state** notification để nhận thông báo khi CPU trở về bình thường

Click **Next**

#### 2.5. Add Name and Description

| Field | Value |
|-------|-------|
| **Alarm name** | `EC2-CPU-High-Alarm` |
| **Alarm description** | `Alert when CPU > 80% for 5 minutes` |

Click **Next**

#### 2.6. Preview and Create

1. Review tất cả cấu hình
2. Click **Create alarm**

---

### Bước 3: Test Alarm

Để test alarm, bạn cần làm cho CPU vượt quá 80%.

**Option 1: Stress Test bằng script**

```bash
# SSH vào EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Install stress tool (Amazon Linux 2)
sudo yum install stress -y

# Run stress test (90% CPU trong 6 phút)
stress --cpu 2 --timeout 360s

# Hoặc dùng yes command (đơn giản hơn)
yes > /dev/null &
yes > /dev/null &
# Kill processes sau khi test
pkill yes
```

**Option 2: Giảm threshold tạm thời**

Thay vì test với CPU 80%, bạn có thể:
1. Edit alarm → giảm threshold xuống 10%
2. Đợi 5 phút → nhận email
3. Sau đó restore lại threshold 80%

---

### Bước 4: Verify Email Alert

Sau khi CPU vượt ngưỡng 5 phút:

1. **Kiểm tra CloudWatch Alarm state**: Chuyển sang `In alarm` (màu đỏ)
2. **Kiểm tra email**: Bạn sẽ nhận email với:
   - Subject: `ALARM: "EC2-CPU-High-Alarm" in <region>`
   - Nội dung: Chi tiết về alarm, threshold, current value, timestamp

**Sample email:**
```
You are receiving this email because your Amazon CloudWatch Alarm 
"EC2-CPU-High-Alarm" in the <region> has entered the ALARM state.

Alarm Details:
- State Change: OK -> ALARM
- Reason: Threshold Crossed: 1 datapoint [85.5] was greater than the threshold (80.0)
- Timestamp: 2024-xx-xx xx:xx:xx UTC
```

---

## 🎉 Kết quả Lab

Sau khi hoàn thành lab, bạn đã:

✅ Cài đặt và cấu hình CloudWatch Agent trên EC2  
✅ Thu thập metrics (CPU, Memory, Disk, Network) từ EC2  
✅ Tạo SNS Topic và Email Subscription  
✅ Tạo CloudWatch Alarm với điều kiện CPU > 80% trong 5 phút  
✅ Nhận email alert khi alarm được trigger  

---

## 📊 Monitoring & Management

### Xem Metrics trên CloudWatch Console

1. **CloudWatch** → **Metrics** → **All metrics**
2. Chọn **CWAgent** (metrics từ agent)
3. Chọn metrics muốn xem: CPU, Memory, Disk, etc.

### Các metrics quan trọng:

| Metric | Namespace | Description |
|--------|-----------|-------------|
| CPUUtilization | AWS/EC2 | CPU usage (%) - built-in |
| cpu_usage_active | CWAgent | CPU usage từ agent |
| mem_used_percent | CWAgent | Memory usage (%) |
| disk_used_percent | CWAgent | Disk usage (%) |

---

## 🛠️ Troubleshooting

### 1. CloudWatch Agent không start được

**Kiểm tra:**
```bash
# Xem log chi tiết
sudo journalctl -u amazon-cloudwatch-agent -n 50

# Kiểm tra config file có đúng format không
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

**Lỗi thường gặp:**
- **IAM Role thiếu permission** → Attach `CloudWatchAgentServerPolicy`
- **Config file sai format** → Validate JSON syntax
- **Port conflict** → Check port 25888 (default agent port)

### 2. Không nhận được email từ SNS

**Kiểm tra:**
- Email subscription đã được confirm chưa? (status = `Confirmed`)
- Check spam folder
- SNS Topic có đúng region với CloudWatch Alarm không?
- Test SNS Topic bằng cách publish test message:
  ```bash
  aws sns publish \
      --topic-arn arn:aws:sns:region:account-id:EC2-CPU-High-Alert \
      --message "Test message"
  ```

### 3. Alarm không trigger dù CPU cao

**Kiểm tra:**
- Alarm state hiện tại là gì? (`OK`, `ALARM`, `INSUFFICIENT_DATA`)
- Xem alarm history: CloudWatch → Alarms → chọn alarm → tab **History**
- Kiểm tra metric có data không: CloudWatch → Metrics → graph metric
- Đảm bảo evaluation period đủ: cần ít nhất 5 phút data

### 4. Metrics không hiển thị trên CloudWatch

**Kiểm tra:**
```bash
# Agent có đang chạy không?
sudo systemctl status amazon-cloudwatch-agent

# Xem log để check errors
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent
```

---

## 💰 Chi phí dự kiến

| Service | Usage | Cost (tháng) |
|---------|-------|--------------|
| CloudWatch Custom Metrics | ~10 metrics | ~$3 |
| CloudWatch Alarms | 1 alarm | ~$0.10 |
| SNS Email | 1000 emails | Free tier |
| **Total** | | **~$3.10/month** |

**Lưu ý:** Chi phí thực tế phụ thuộc vào số lượng metrics và alarms bạn tạo.

---

## 🧹 Clean Up (Dọn dẹp resources)

Sau khi hoàn thành lab, xóa resources để tránh phát sinh chi phí:

```bash
# 1. Stop CloudWatch Agent trên EC2
sudo systemctl stop amazon-cloudwatch-agent
sudo systemctl disable amazon-cloudwatch-agent

# 2. Xóa CloudWatch Alarm (qua Console hoặc CLI)
aws cloudwatch delete-alarms --alarm-names EC2-CPU-High-Alarm

# 3. Xóa SNS Subscription và Topic
aws sns delete-topic --topic-arn arn:aws:sns:region:account-id:EC2-CPU-High-Alert

# 4. (Tùy chọn) Terminate EC2 instance nếu chỉ dùng cho lab
```

---

## 📚 Tài liệu tham khảo

- [CloudWatch Agent Official Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [Amazon SNS Documentation](https://docs.aws.amazon.com/sns/)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)

---

## 📝 Next Steps

Sau khi hoàn thành lab này, bạn có thể:

1. **Tạo thêm alarms cho metrics khác:**
   - Memory usage > 90%
   - Disk usage > 85%
   - Network bandwidth anomalies

2. **Tích hợp với Lambda:**
   - Auto-scale khi CPU cao
   - Auto-restart services
   - Send notifications đến Slack/Teams

3. **Tạo CloudWatch Dashboard:**
   - Visualize tất cả metrics
   - Custom widgets
   - Share với team

4. **Advanced monitoring:**
   - Thu thập custom application logs
   - Application-level metrics
   - Distributed tracing với X-Ray

---

## ✍️ Ghi chú

- Lab này được thiết kế cho môi trường development/learning
- Trong production, cần cấu hình thêm:
  - Multiple alarm thresholds
  - Auto-remediation actions
  - Log aggregation
  - Advanced security configurations

---

**Chúc bạn hoàn thành lab thành công! 🚀**

Nếu có vấn đề gì, tham khảo phần Troubleshooting hoặc docs/ folder.
