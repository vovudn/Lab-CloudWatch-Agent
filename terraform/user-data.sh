#!/bin/bash
set -e

# User data script for CloudWatch Agent installation and configuration
# This script runs at instance launch

echo "=== CloudWatch Agent Installation Started ==="
date

# Update system
yum update -y

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create config file
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json << 'EOF'
${config_json}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Enable agent to start on boot
systemctl enable amazon-cloudwatch-agent

# Install stress tool for testing
yum install -y stress

# Create test script
cat > /home/ec2-user/test-cpu-load.sh << 'TESTEOF'
#!/bin/bash
echo "Starting CPU stress test..."
echo "This will run for 6 minutes to trigger the alarm"
stress --cpu 2 --timeout 360s
echo "Test completed!"
TESTEOF

chmod +x /home/ec2-user/test-cpu-load.sh
chown ec2-user:ec2-user /home/ec2-user/test-cpu-load.sh

# Create verification script
cat > /home/ec2-user/verify-setup.sh << 'VERIFYEOF'
#!/bin/bash
echo "=== Verifying CloudWatch Agent Setup ==="
echo ""
echo "1. Agent Status:"
sudo systemctl status amazon-cloudwatch-agent --no-pager
echo ""
echo "2. Agent Query:"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a query
echo ""
echo "3. Config File:"
if [ -f "/opt/aws/amazon-cloudwatch-agent/bin/config.json" ]; then
    echo "✓ Config file exists"
else
    echo "✗ Config file missing"
fi
VERIFYEOF

chmod +x /home/ec2-user/verify-setup.sh
chown ec2-user:ec2-user /home/ec2-user/verify-setup.sh

echo "=== CloudWatch Agent Installation Completed ==="
date
