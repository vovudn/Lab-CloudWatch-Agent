# 🚀 Terraform Version - CloudWatch Agent Lab

## ✨ Mới: Infrastructure as Code với Terraform!

Lab này giờ có **Terraform infrastructure** hoàn chỉnh để deploy toàn bộ tự động!

---

## 🎯 2 Cách thực hiện Lab

### Option 1: Manual Setup 📚

**Suitable for:** AWS beginners wanting to understand each step

**Guide:** [README.md](README.md)

**Time:** 45-60 minutes

**Pros:**
- ✅ Understand each step
- ✅ Learn troubleshooting
- ✅ Deep AWS knowledge

**Cons:**
- ❌ Time-consuming
- ❌ Error-prone
- ❌ Hard to reproduce

---

### Option 2: Terraform (Production-Ready) ⚡ **RECOMMENDED**

**Suitable for:** Everyone! Fast, reliable, production-ready

**Guide:**
- [terraform/README.md](terraform/README.md) - Complete guide
- [terraform/QUICK-START.md](terraform/QUICK-START.md) - 5 minutes

**Time:** 5 minutes setup + 5 minutes test = **10 minutes total**

**Ưu điểm:**
- ✅ **Infrastructure as Code** (IaC best practice)
- ✅ **Reproducible** - Chạy lại bao nhiêu lần cũng được
- ✅ **Version control** - Track changes
- ✅ **Automated** - 1 command deploy toàn bộ
- ✅ **Clean destroy** - `terraform destroy` xóa sạch
- ✅ **Production-ready** - Đúng cách làm thực tế
- ✅ **Fast** - 5 phút deploy xong

**Terraform tạo gì:**
- VPC + Subnet + Internet Gateway + Route Table
- Security Group (SSH access)
- IAM Role với CloudWatchAgentServerPolicy
- EC2 instance với CloudWatch Agent pre-installed
- SNS Topic + Email Subscription
- CloudWatch Alarm (CPU > 80%)
- CloudWatch Dashboard
- SSH Key pair tự động

---

## 🚀 Quick Start với Terraform

### 3 Commands duy nhất:

```bash
cd terraform/

# 1. Copy config
cp terraform.tfvars.example terraform.tfvars
# Edit email_address trong file này

# 2. Deploy toàn bộ
terraform init
terraform apply

# 3. Clean up khi xong
terraform destroy
```

**That's it! 🎉**

---

## 📊 So sánh 2 options

| Feature | Manual | Terraform |
|---------|--------|-----------|
| **Setup time** | 60-90 min | 5 min |
| **Difficulty** | Medium | Easy |
| **Reproducible** | ❌ | ✅ |
| **Best practice** | ❌ | ✅ |
| **Learning value** | High (AWS) | High (IaC) |
| **Production use** | ❌ | ✅ |
| **Version control** | Partial | ✅ |
| **Clean up** | Manual | `terraform destroy` |
| **Error prone** | Yes | No |

---

## 💡 Recommendation

**For Everyone:**
→ **Start with Terraform!** [terraform/README.md](terraform/README.md)

**Want to learn manually?**
→ Read [README.md](README.md) after Terraform

**Best learning path:**
1. Run Terraform (10 min) - See it work
2. Read README.md - Understand how it works
3. Compare with terraform/*.tf files - Learn IaC

---

## 📁 Project Structure

```
Lab-CloudWatch-Agent/
│
├── 00-START-HERE.md              ← START HERE
├── TERRAFORM-README.md           ← This file
├── README.md                     ← Manual setup guide
│
├── terraform/ ⚡ RECOMMENDED
│   ├── README.md                 ← Terraform guide
│   ├── QUICK-START.md            ← 5 min setup
│   ├── *.tf files                ← Infrastructure code
│   ├── Makefile                  ← Make commands
│   └── terraform.tfvars.example  ← Config template
│
├── docs/
│   ├── TROUBLESHOOTING.md        ← Common issues
│   └── FAQ.md                    ← 26 FAQs
│
└── Support files:
    ├── cloudwatch-config.json    ← Agent config
    ├── test-cpu-load.sh          ← Test script
    └── verify-setup.sh           ← Verify script
```

---

## 🎯 Bắt đầu ngay!

### Terraform (Recommended):
```bash
cd terraform/
cat README.md
```

### Manual:
```bash
cat HUONG-DAN-TIENG-VIET.md
```

---

## 📚 Learning Path Suggestions

### Path 1: Complete Learning (Beginners)
```
Day 1: Manual setup
→ Read HUONG-DAN-TIENG-VIET.md
→ Do step-by-step
→ Understand each AWS service

Day 2: Terraform
→ Read terraform/README.md
→ Compare with manual setup
→ Learn IaC concepts
```

### Path 2: Fast Track (Experienced)
```
→ Go directly to terraform/
→ terraform apply
→ Done in 10 minutes
```

---

## 💰 Cost Comparison

**Same cost cho cả 2 options:**
- EC2 t2.micro: Free tier or ~$8/month
- CloudWatch: ~$3/month
- Total: ~$3-11/month

**After cleanup:** $0

---

## 🎓 What You'll Learn

### Manual Path:
- AWS EC2, IAM, CloudWatch, SNS fundamentals
- Bash scripting
- Troubleshooting skills
- Manual configuration

### Terraform Path:
- Infrastructure as Code (IaC)
- Terraform syntax và workflow
- Version-controlled infrastructure
- Production best practices
- Automated deployment

**Ideal:** Learn both! 🚀

---

## 🆚 When to Use Which?

### Use Manual when:
- 🎓 Learning AWS for the first time
- 📚 Want to understand internals
- 🐛 Debugging specific issues
- 🔬 Experimenting with configurations

### Use Terraform when:
- 🚀 Need fast deployment
- 👥 Working in a team
- 🔄 Need to reproduce environment
- 🏢 Production deployment
- 📝 Want infrastructure in Git
- ⚡ Best practices matter

---

## 📞 Support

**Terraform issues:**
- See: [terraform/README.md](terraform/README.md)
- Check: [terraform/QUICK-START.md](terraform/QUICK-START.md)

**AWS/Lab issues:**
- See: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Check: [docs/FAQ.md](docs/FAQ.md)

---

## 🌟 Why Terraform is Better

1. **One command deployment:**
   ```bash
   terraform apply
   ```
   vs 20+ manual steps

2. **Guaranteed reproducible:**
   - Same result every time
   - No human errors

3. **Easy cleanup:**
   ```bash
   terraform destroy
   ```
   vs deleting 10+ resources manually

4. **Version control:**
   - Commit infrastructure code
   - Review changes (PR)
   - Rollback if needed

5. **Documentation as code:**
   - Infrastructure is self-documenting
   - No outdated docs

6. **Production standard:**
   - This is how real companies do it
   - Learn valuable skills

---

## 🎉 Conclusion

**New to AWS?**
→ Start with Manual ([HUONG-DAN-TIENG-VIET.md](HUONG-DAN-TIENG-VIET.md))

**Know AWS basics?**
→ Jump to Terraform ([terraform/README.md](terraform/README.md))

**Want best practice?**
→ Terraform is the way! ⚡

**Want to learn everything?**
→ Do Manual first, then Terraform second 🎓

---

**Choose your path and start learning! 🚀**

[← Back to 00-START-HERE.md](00-START-HERE.md)
