#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🎯 QuantTrader-K8s-Simulator Prerequisites Check"
echo "=============================================="

# Check OS
log_info "1. Checking operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    log_success "macOS detected"
else
    log_error "This project requires macOS"
    exit 1
fi

# Check system resources
log_info "2. Checking system resources..."
TOTAL_MEMORY_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
if [ $TOTAL_MEMORY_GB -ge 8 ]; then
    log_success "Memory: ${TOTAL_MEMORY_GB}GB (minimum 8GB required)"
else
    log_error "Insufficient memory: ${TOTAL_MEMORY_GB}GB (minimum 8GB required)"
    exit 1
fi

# Check tools
log_info "3. Checking required tools..."

# AWS CLI
if command -v aws &> /dev/null; then
    log_success "AWS CLI: $(aws --version | head -1)"
else
    log_error "AWS CLI not found"
    exit 1
fi

# Terraform
if command -v terraform &> /dev/null; then
    log_success "Terraform: $(terraform version | head -1)"
else
    log_error "Terraform not found"
    exit 1
fi

# kubectl
if command -v kubectl &> /dev/null; then
    log_success "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"
else
    log_error "kubectl not found"
    exit 1
fi

# Helm
if command -v helm &> /dev/null; then
    log_success "Helm: $(helm version --short)"
else
    log_error "Helm not found"
    exit 1
fi

# Docker
if command -v docker &> /dev/null; then
    log_success "Docker: $(docker --version)"
else
    log_error "Docker not found"
    exit 1
fi

# Kind
if command -v kind &> /dev/null; then
    log_success "Kind: $(kind version)"
else
    log_warning "Kind not found (optional for local development)"
fi

# VS Code
if command -v code &> /dev/null; then
    log_success "VS Code is installed"
else
    log_warning "VS Code not found (optional)"
fi

# Network connectivity
log_info "4. Checking network connectivity..."
if curl -s --max-time 10 https://aws.amazon.com > /dev/null; then
    log_success "Internet connectivity verified"
else
    log_error "No internet connectivity"
    exit 1
fi

# AWS credentials
log_info "5. Checking AWS credentials..."
if aws sts get-caller-identity --profile quanttrader-dev &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile quanttrader-dev)
    log_success "AWS credentials configured for account: $ACCOUNT_ID"
else
    log_warning "AWS credentials not configured for profile 'quanttrader-dev'"
    log_info "Run: aws configure --profile quanttrader-dev"
fi

echo ""
log_success "Prerequisites check completed!"
echo ""
log_info "Next steps:"
echo "  1. Configure AWS credentials if not done: aws configure --profile quanttrader-dev"
echo "  2. Run setup: ./scripts/setup-1.1.sh"
echo "  3. Verify installation: ./scripts/verify-1.1.sh"
