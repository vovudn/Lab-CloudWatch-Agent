# Frequently Asked Questions (FAQ)

## 🤔 General Questions

### Q1: CloudWatch Agent là gì?
**A:** CloudWatch Agent là một phần mềm cài đặt trên EC2 instance để thu thập metrics và logs chi tiết hơn so với built-in EC2 metrics. Nó cho phép bạn monitor:
- CPU utilization per core
- Memory usage (không có trong default EC2 metrics)
- Disk usage và I/O
- Network metrics
- Custom application logs

### Q2: Tại sao cần CloudWatch Agent khi EC2 đã có sẵn CPU metrics?
**A:** EC2 default metrics chỉ cung cấp:
- CPU Utilization (tổng thể)
- Network In/Out
- Disk Read/Write

CloudWatch Agent bổ sung:
- **Memory usage** (quan trọng, không có trong default)
- **Disk space usage** (%, free space)
- Per-core CPU metrics
- Process-level metrics
- Custom logs collection

### Q3: CloudWatch Agent có miễn phí không?
**A:** Agent software miễn phí, nhưng bạn phải trả tiền cho:
- Custom metrics: ~$0.30/metric/month
- CloudWatch Alarms: ~$0.10/alarm/month
- Log ingestion: $0.50/GB
- Log storage: $0.03/GB/month

**Ví dụ:** Thu thập 10 metrics + 1 alarm ≈ $3-4/month

---

## 🔧 Installation Questions

### Q4: Instance types nào support CloudWatch Agent?
**A:** Tất cả EC2 instance types đều support. Nhưng lưu ý:
- T2/T3 instances: Agent consume ít resources
- Micro/Small instances: Cân nhắc số lượng metrics

### Q5: Có thể cài CloudWatch Agent trên On-Premises servers không?
**A:** Có! CloudWatch Agent hỗ trợ:
- EC2 instances
- On-Premises servers (Linux/Windows)
- Hybrid environments

Cần có IAM credentials (access key/secret key) thay vì IAM Role.

### Q6: Có thể cài CloudWatch Agent trên container/Kubernetes không?
**A:** Có, nhưng khuyến nghị sử dụng:
- **ECS**: ECS Container Insights (built-in)
- **EKS**: CloudWatch Container Insights cho Kubernetes
- **Docker**: Có thể cài agent trong container, nhưng không tối ưu

---

## ⚙️ Configuration Questions

### Q7: File cấu hình CloudWatch Agent ở đâu?
**A:** Sau khi chạy wizard, file config được lưu tại:
```
/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

Có thể edit file này trực tiếp thay vì re-run wizard.

### Q8: Làm sao để update configuration?
**A:** Sau khi edit `config.json`:
```bash
# Restart agent để apply changes
sudo systemctl restart amazon-cloudwatch-agent

# Verify new config
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query
```

### Q9: Có thể dùng SSM Parameter Store để lưu config không?
**A:** Có! Best practice cho production:
```bash
# Store config in SSM
aws ssm put-parameter \
    --name "AmazonCloudWatch-linux" \
    --type "String" \
    --value file://config.json

# Agent fetch config from SSM
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s \
    -c ssm:AmazonCloudWatch-linux
```

Lợi ích: Centralized config management cho nhiều instances.

---

## 📊 Metrics Questions

### Q10: Metrics mất bao lâu để xuất hiện trên CloudWatch Console?
**A:** 
- First time: 5-10 phút
- Subsequent updates: 1-5 phút (tùy collection interval)

### Q11: Có thể giảm collection interval xuống dưới 60 giây không?
**A:** Có, minimum là 1 giây. Nhưng lưu ý:
- Chi phí tăng (nhiều data points hơn)
- Agent consume nhiều CPU/Memory hơn
- Chỉ nên dùng cho critical metrics

```json
{
  "metrics_collection_interval": 10
}
```

### Q12: Metrics từ CloudWatch Agent có namespace gì?
**A:** Default namespace: `CWAgent`

Có thể customize trong config:
```json
{
  "metrics": {
    "namespace": "MyCustomNamespace"
  }
}
```

---

## 🚨 Alarm Questions

### Q13: Có thể tạo alarm cho Memory metrics không?
**A:** Có! Đó là lý do chính để dùng CloudWatch Agent.

**Steps:**
1. Cài CloudWatch Agent (để có memory metrics)
2. CloudWatch → Metrics → CWAgent → Memory
3. Create alarm với metric: `mem_used_percent`

### Q14: Alarm evaluation period là gì?
**A:** Là khoảng thời gian CloudWatch đánh giá metrics.

**Ví dụ:**
- Period: 5 minutes
- Datapoints: 1 out of 1 → Alarm sau 5 phút vi phạm
- Datapoints: 3 out of 5 → Alarm sau 3/5 periods vi phạm (15 phút trong 25 phút)

### Q15: Có thể gửi alert qua Slack/Teams thay vì email không?
**A:** Có! Qua Lambda:

SNS → Lambda → Slack/Teams webhook

**Lambda example:**
```python
import json
import urllib3

http = urllib3.PoolManager()

def lambda_handler(event, context):
    message = event['Records'][0]['Sns']['Message']
    
    slack_message = {
        'text': f'🚨 CloudWatch Alarm: {message}'
    }
    
    http.request(
        'POST',
        'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
        body=json.dumps(slack_message),
        headers={'Content-Type': 'application/json'}
    )
```

---

## 🔒 Security Questions

### Q16: IAM Role cần permissions gì?
**A:** Minimum permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

AWS managed policy: `CloudWatchAgentServerPolicy` (recommended)

### Q17: CloudWatch Agent có access được sensitive data không?
**A:** Agent chỉ đọc:
- System metrics (CPU, memory, disk)
- Log files bạn specify trong config

**Best practices:**
- Không collect logs chứa secrets
- Encrypt logs at rest (CloudWatch tự động làm)
- Use IAM policies để restrict access

---

## 💰 Cost Questions

### Q18: Chi phí CloudWatch Agent như thế nào?
**A:** Breakdown:
- Agent software: **Free**
- Custom metrics: $0.30/metric/month (first 10,000 metrics)
- CloudWatch Alarms: $0.10/alarm/month
- Log ingestion: $0.50/GB
- Log storage: $0.03/GB/month

**Example:**
- 10 metrics + 2 alarms + 5GB logs = ~$7/month

### Q19: Làm sao để giảm chi phí?
**A:**
1. **Thu thập ít metrics hơn:**
   ```json
   {
     "metrics_collected": {
       "cpu": {},
       "mem": {}
       // Remove netstat, diskio nếu không cần
     }
   }
   ```

2. **Tăng collection interval:**
   ```json
   {
     "metrics_collection_interval": 300
   }
   ```

3. **Set log retention:**
   ```bash
   aws logs put-retention-policy \
       --log-group-name /aws/ec2/app \
       --retention-in-days 7
   ```

4. **Sử dụng metric filters:** Extract metrics từ logs thay vì store toàn bộ logs

---

## 🛠️ Troubleshooting Questions

### Q20: Agent không start sau khi cài đặt?
**A:** Check theo thứ tự:
1. IAM Role có `CloudWatchAgentServerPolicy`?
2. Config file valid JSON?
3. Xem logs: `sudo journalctl -u amazon-cloudwatch-agent -n 50`

### Q21: Metrics không xuất hiện trên CloudWatch?
**A:** 
1. Agent đang chạy: `sudo systemctl status amazon-cloudwatch-agent`
2. Đợi 5-10 phút cho first data
3. Check đúng region: CloudWatch Console region = EC2 region
4. Verify IAM permissions

### Q22: Email từ SNS không nhận được?
**A:**
1. Check subscription status: `Confirmed` (không phải `Pending`)
2. Check spam folder
3. Test SNS trực tiếp:
   ```bash
   aws sns publish \
       --topic-arn arn:aws:sns:region:account:topic \
       --message "Test"
   ```

---

## 🎯 Use Case Questions

### Q23: Có nên enable CloudWatch Agent cho tất cả EC2 instances?
**A:** Tùy use case:
- **Production instances:** Nên enable (monitoring quan trọng)
- **Dev/Test instances:** Có thể skip để tiết kiệm chi phí
- **Short-lived instances:** Không cần thiết

### Q24: CloudWatch Agent vs Datadog/New Relic?
**A:** 

| Feature | CloudWatch Agent | Datadog |
|---------|------------------|---------|
| **Setup** | Phức tạp hơn | Dễ hơn |
| **Cost** | Rẻ hơn | Đắt hơn |
| **Features** | Basic monitoring | Advanced APM, tracing |
| **Integration** | AWS native | Multi-cloud |

**Khuyến nghị:**
- Dự án nhỏ, AWS-only → CloudWatch
- Enterprise, multi-cloud → Datadog

---

## 📚 Learning Resources

### Q25: Tài liệu official ở đâu?
**A:** 
- [CloudWatch Agent Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [AWS Training](https://aws.amazon.com/training/)

### Q26: Có AWS certification nào cover CloudWatch không?
**A:** 
- **AWS Certified Solutions Architect - Associate**: CloudWatch basics
- **AWS Certified SysOps Administrator**: CloudWatch deep dive
- **AWS Certified DevOps Engineer**: Advanced monitoring & automation

---

**Có câu hỏi khác? Tham khảo:**
- [AWS Forums](https://repost.aws/)
- [Stack Overflow - aws-cloudwatch tag](https://stackoverflow.com/questions/tagged/aws-cloudwatch)
