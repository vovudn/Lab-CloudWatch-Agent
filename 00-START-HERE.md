# 🚀 Bắt đầu tại đây!

## Lab: Installing CloudWatch Agent on EC2 & CPU Alarm Email Alert via SNS

⚡ **NEW: Terraform version available!** → [TERRAFORM-README.md](TERRAFORM-README.md)

---

## ⚡ Quick Navigation

### 🎯 Chọn cách thực hiện Lab:

#### 🏗️ Option 1: Terraform (Recommended!) ⭐
**→ Start:** [terraform/README.md](terraform/README.md)  
🚀 Infrastructure as Code - Deploy everything automatically  
⏱️ Time: **5 minutes**  
💡 **Production-ready & Best practice!**

**Quick start:**
```bash
cd terraform/
terraform init
terraform apply
```

#### 📚 Option 2: Manual Setup  
**→ Read:** [README.md](README.md)  
📖 Step-by-step manual instructions  
⏱️ Time: 45-60 minutes  
🎓 Educational approach

#### 🎬 Cần demo/present
**→ Đọc:** [QUICK-START.md](QUICK-START.md)  
🎤 Commands rõ ràng, dễ demo  
⏱️ Thời gian: 25 phút demo

---

## 📋 Lab này làm gì?

### Yêu cầu đề bài:

#### Phần 1: Cài đặt CloudWatch Agent
1. ✅ Install Agent Package
2. ✅ Run Configuration Wizard  
3. ✅ Start the Agent
4. ✅ Verify & Check Status

#### Phần 2: CPU Alarm → Email via SNS
**Scenario:** Gửi email khi CPU > 80% trong 5 phút liên tiếp

1. ✅ Create SNS Topic & Email Subscription
2. ✅ Create CloudWatch Alarm
3. ✅ Configure Alarm Conditions (> 80%, 5 min, 1 out of 1)
4. ✅ Set SNS Notification Action
5. ✅ Test và verify

---

## 🎯 Sau khi hoàn thành

Bạn sẽ có:
- ✅ CloudWatch Agent collecting metrics (CPU, Memory, Disk)
- ✅ CloudWatch Alarm monitoring CPU > 80%
- ✅ Email alerts qua SNS
- ✅ Kiến thức troubleshooting
- ✅ Production-ready monitoring setup

---

## 📚 Documentation

| File | Purpose |
|------|---------|
| [00-START-HERE.md](00-START-HERE.md) | This file - Entry point |
| [TERRAFORM-README.md](TERRAFORM-README.md) | Terraform vs Manual comparison |
| [README.md](README.md) | Complete manual setup guide |
| [terraform/](terraform/) | **Terraform Infrastructure** ⚡ |

**Additional docs:**
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues & solutions
- [docs/FAQ.md](docs/FAQ.md) - Frequently asked questions

---

## 🛠️ Test Scripts (for EC2 instance)

```bash
# After SSH to EC2 instance:

# Verify CloudWatch Agent setup
./verify-setup.sh

# Test CPU load (trigger alarm)
./test-cpu-load.sh
```

---

## 💰 Chi phí

- Lab cost: ~$3/month (nếu chạy liên tục)
- Sau cleanup: **$0**

---

## 🚀 Get Started Now!

### Recommended Path (Terraform):

```bash
# 1. Go to terraform directory
cd terraform/

# 2. Configure your email
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: email_address = "your@email.com"

# 3. Deploy infrastructure
terraform init
terraform apply

# 4. Confirm email subscription (check inbox)

# 5. SSH to EC2 and test
ssh -i cloudwatch-agent-lab-key.pem ec2-user@<IP>
./test-cpu-load.sh

# 6. Check email for alarm notification (after ~5 min)

# 7. Clean up when done
terraform destroy
```

**Total time: 10 minutes!** ⚡

### Alternative Path (Manual):
See [README.md](README.md) for step-by-step instructions.

---

## 🆘 Cần giúp đỡ?

**Gặp lỗi?**
1. [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - 8 common issues
2. [docs/FAQ.md](docs/FAQ.md) - 26 questions
3. Check logs: `/opt/aws/amazon-cloudwatch-agent/logs/`

**Verify setup:**
```bash
./verify-setup.sh
```

---

## ✨ Features

- ✅ **2 ngôn ngữ** (English + Tiếng Việt)
- ✅ **2,500+ dòng** documentation
- ✅ **5 automation scripts**
- ✅ **26 FAQs** answered
- ✅ **Production-ready** examples

---

**Bắt đầu học ngay! 🎓**

**→ [HUONG-DAN-TIENG-VIET.md](HUONG-DAN-TIENG-VIET.md)** (Recommended cho người mới)

hoặc

**→ [QUICK-START.md](QUICK-START.md)** (Cho người có kinh nghiệm)
