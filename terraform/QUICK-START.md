# Terraform Quick Start - 5 Minutes

## 🚀 Deploy in 5 Minutes

### 1. Configure Email (30 seconds)

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
email_address = "your-email@example.com"  # CHANGE THIS
```

### 2. Deploy (3 minutes)

```bash
terraform init
terraform apply -auto-approve
```

### 3. Confirm Email (1 minute)

Check email → Click confirmation link

### 4. Connect & Test (1 minute)

```bash
# Get SSH command
terraform output -raw ssh_command

# SSH to EC2
ssh -i cloudwatch-agent-lab-key.pem ec2-user@<IP>

# Test
./test-cpu-load.sh
```

### 5. Wait for Alert (5 minutes)

After 5 minutes → Check email for alert!

---

## 🧹 Clean Up

```bash
terraform destroy -auto-approve
```

---

## 📋 Using Makefile (Even Easier!)

```bash
# Setup everything
make setup EMAIL=your-email@example.com

# SSH to instance
make ssh

# Show status
make status

# Destroy
make destroy
```

---

**That's it! 🎉**
