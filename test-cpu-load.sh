#!/bin/bash

#############################################
# Script: CPU Load Test for CloudWatch Alarm
# Description: Tạo CPU load để test alarm
# Usage: ./test-cpu-load.sh
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo "=========================================="
echo "  CPU Load Test Script"
echo "=========================================="
echo

print_info "Script này sẽ tạo CPU load cao để test CloudWatch Alarm"
echo

# Check if stress is installed
if ! command -v stress &> /dev/null; then
    print_info "Installing stress tool..."
    
    if command -v yum &> /dev/null; then
        sudo yum install stress -y
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install stress -y
    else
        echo "Không thể cài đặt stress tool tự động"
        echo "Sử dụng alternative method..."
        
        # Alternative: use yes command
        print_info "Sẽ dùng 'yes' command để tạo CPU load"
        echo "Nhấn Ctrl+C để dừng test"
        sleep 3
        
        yes > /dev/null &
        yes > /dev/null &
        yes > /dev/null &
        yes > /dev/null &
        
        print_success "CPU load đã được tạo (4 processes)"
        echo
        echo "Để stop, chạy: pkill yes"
        exit 0
    fi
fi

# Run stress test
print_info "Đang chạy stress test..."
echo "- CPU cores: $(nproc)"
echo "- Target: 90% CPU usage"
echo "- Duration: 7 minutes (để trigger alarm sau 5 phút)"
echo
echo "Nhấn Ctrl+C để dừng test sớm"
echo

stress --cpu $(nproc) --timeout 420s --verbose

print_success "Stress test hoàn tất!"
echo
print_info "Kiểm tra CloudWatch Alarm sau vài phút..."
