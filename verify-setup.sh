#!/bin/bash

#############################################
# Script: Verify CloudWatch Agent Setup
# Description: Kiểm tra toàn bộ setup có đúng không
# Usage: ./verify-setup.sh
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_check() {
    echo -e "${YELLOW}[CHECKING]${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[✓ OK]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
}

FAILED=0

echo "=========================================="
echo "  CloudWatch Agent Setup Verification"
echo "=========================================="
echo

# Check 1: IAM Role
print_check "IAM Role attached to EC2..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
IAM_ROLE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null || echo "")

if [ -z "$IAM_ROLE" ]; then
    print_fail "No IAM Role found. Attach role with CloudWatchAgentServerPolicy"
    FAILED=$((FAILED+1))
else
    print_ok "IAM Role: $IAM_ROLE"
fi
echo

# Check 2: Agent installed
print_check "CloudWatch Agent package installed..."
if [ -f "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl" ]; then
    print_ok "Agent package installed"
else
    print_fail "Agent not installed. Run: sudo yum install amazon-cloudwatch-agent -y"
    FAILED=$((FAILED+1))
fi
echo

# Check 3: Agent running
print_check "CloudWatch Agent service status..."
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    print_ok "Agent is running"
    
    # Get detailed status
    STATUS=$(sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a query 2>/dev/null)
    if echo "$STATUS" | grep -q '"status": "running"'; then
        print_ok "Agent status: running"
    else
        print_fail "Agent status check failed"
        FAILED=$((FAILED+1))
    fi
else
    print_fail "Agent is not running. Start with: sudo systemctl start amazon-cloudwatch-agent"
    FAILED=$((FAILED+1))
fi
echo

# Check 4: Config file exists
print_check "Config file exists..."
if [ -f "/opt/aws/amazon-cloudwatch-agent/bin/config.json" ]; then
    print_ok "Config file found"
    
    # Validate JSON
    if python3 -m json.tool /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null 2>&1; then
        print_ok "Config file is valid JSON"
    else
        print_fail "Config file has invalid JSON syntax"
        FAILED=$((FAILED+1))
    fi
else
    print_fail "Config file not found. Run wizard or copy config file"
    FAILED=$((FAILED+1))
fi
echo

# Check 5: Metrics in CloudWatch
print_check "Checking if metrics are being sent..."
if command -v aws &> /dev/null; then
    METRICS=$(aws cloudwatch list-metrics --namespace CWAgent 2>/dev/null | grep -c "MetricName" || echo "0")
    
    if [ "$METRICS" -gt 0 ]; then
        print_ok "Found $METRICS metrics in CloudWatch (namespace: CWAgent)"
    else
        print_fail "No metrics found in CloudWatch. Wait 5-10 minutes or check IAM permissions"
        FAILED=$((FAILED+1))
    fi
else
    print_fail "AWS CLI not installed. Cannot check CloudWatch metrics"
    echo "         Install with: sudo yum install aws-cli -y"
    FAILED=$((FAILED+1))
fi
echo

# Summary
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    print_ok "All checks passed! Setup is complete."
    echo
    echo "Next steps:"
    echo "  1. Wait 5-10 minutes for metrics to appear in CloudWatch Console"
    echo "  2. Create SNS Topic for email alerts"
    echo "  3. Create CloudWatch Alarm for CPU > 80%"
    echo "  4. Test with: stress --cpu 2 --timeout 360s"
else
    print_fail "$FAILED check(s) failed. Fix issues above."
    echo
    echo "Common fixes:"
    echo "  - Attach IAM Role: EC2 Console → Instance → Actions → Security → Modify IAM Role"
    echo "  - Install agent: sudo yum install amazon-cloudwatch-agent -y"
    echo "  - Start agent: sudo systemctl start amazon-cloudwatch-agent"
    echo "  - Check logs: sudo tail -50 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
fi
echo "=========================================="

exit $FAILED
