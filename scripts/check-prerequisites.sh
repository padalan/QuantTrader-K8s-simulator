#!/usr/bin/env bash
# check-prerequisites.sh | Validate system requirements before setup
# QuantTrader-K8s-Simulator Phase 1 - Prerequisites Check

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Version comparison function
version_compare() {
    local version1=$1
    local version2=$2
    local op=$3
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        elif ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done
    
    return 0
}

log_info "QuantTrader-K8s-Simulator Prerequisites Check"
echo "=============================================="

# Check operating system
log_info "1. Checking operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_VERSION=$(sw_vers -productVersion)
    log_success "macOS detected: $OS_VERSION"
    
    # Check if macOS version is sufficient (12.0+)
    if version_compare "$OS_VERSION" "12.0" ">=" || version_compare "$OS_VERSION" "12.0" "="; then
        log_success "macOS version is sufficient"
    else
        log_error "macOS 12.0+ required, found: $OS_VERSION"
        exit 1
    fi
else
    log_error "This project requires macOS"
    exit 1
fi

# Check system resources
log_info "2. Checking system resources..."
TOTAL_MEMORY=$(sysctl -n hw.memsize)
TOTAL_MEMORY_GB=$((TOTAL_MEMORY / 1024 / 1024 / 1024))

if [ $TOTAL_MEMORY_GB -ge 8 ]; then
    log_success "Memory: ${TOTAL_MEMORY_GB}GB (minimum 8GB required)"
else
    log_error "Insufficient memory: ${TOTAL_MEMORY_GB}GB (minimum 8GB required)"
    exit 1
fi

# Check disk space
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/Gi//')
if [ "${AVAILABLE_SPACE%.*}" -ge 10 ]; then
    log_success "Disk space: ${AVAILABLE_SPACE}GB available (minimum 10GB required)"
else
    log_error "Insufficient disk space: ${AVAILABLE_SPACE}GB (minimum 10GB required)"
    exit 1
fi

# Check Homebrew
log_info "3. Checking Homebrew..."
if command -v brew &> /dev/null; then
    BREW_VERSION=$(brew --version | head -1 | awk '{print $2}')
    log_success "Homebrew installed: $BREW_VERSION"
else
    log_error "Homebrew not found. Install with:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check required tools
log_info "4. Checking required tools..."

check_tool() {
    local tool=$1
    local min_version=$2
    local get_version_cmd=$3
    
    if command -v $tool &> /dev/null; then
        local current_version=$($get_version_cmd)
        if version_compare "$current_version" "$min_version" ">="; then
            log_success "$tool: $current_version (>= $min_version)"
        else
            log_error "$tool version $current_version is below minimum $min_version"
            return 1
        fi
    else
        log_error "$tool not found"
        return 1
    fi
}

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | awk '{print $1}' | cut -d'/' -f2)
    if version_compare "$AWS_VERSION" "2.28.0" ">="; then
        log_success "AWS CLI: $AWS_VERSION (>= 2.28.0)"
    else
        log_error "AWS CLI version $AWS_VERSION is below minimum 2.28.0"
        exit 1
    fi
else
    log_error "AWS CLI not found"
    exit 1
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version | head -1 | awk '{print $2}' | sed 's/v//')
    if version_compare "$TF_VERSION" "1.5.0" ">="; then
        log_success "Terraform: v$TF_VERSION (>= 1.5.0)"
    else
        log_error "Terraform version $TF_VERSION is below minimum 1.5.0"
        exit 1
    fi
else
    log_error "Terraform not found"
    exit 1
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    KUBE_VERSION=$(kubectl version --client --short 2>/dev/null | grep "Client Version" | awk "{print \$3}" | sed "s/v//")
    if [ -n "$KUBE_VERSION" ] && version_compare "$KUBE_VERSION" "1.27.0" ">="; then
        log_success "kubectl: v$KUBE_VERSION (>= 1.27.0)"
    else
        log_warning "kubectl version check failed or below minimum 1.27.0 (found: $KUBE_VERSION)"
    fi
else
    log_error "kubectl not found"
    exit 1
fi
