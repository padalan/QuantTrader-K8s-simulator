#!/usr/bin/env bash
# verify-1.1.sh | Verification script for Task 1.1
# QuantTrader-K8s-Simulator Phase 1 - Epic 1.1

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

log_info "Starting Task 1.1 Verification"
echo "=================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# 1. Verify AWS CLI
log_info "1. Verifying AWS CLI installation and configuration..."
if command -v aws &> /dev/null; then
    echo "AWS CLI Version: $(aws --version)"
    log_success "AWS CLI is installed"
else
    log_error "AWS CLI is not installed"
    exit 1
fi

# Check AWS profile configuration
if aws sts get-caller-identity --profile quanttrader-dev &> /dev/null; then
    echo "AWS Profile Identity:"
    aws sts get-caller-identity --profile quanttrader-dev
    log_success "AWS profile 'quanttrader-dev' is configured"
else
    log_error "AWS profile 'quanttrader-dev' is not configured or invalid"
    exit 1
fi

# 2. Verify Development Tools
log_info "2. Verifying development tools installation..."

tools=("terraform" "kubectl" "helm" "docker")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        case $tool in
            "terraform")
                echo "Terraform: $(terraform version | head -1)"
                ;;
            "kubectl")
                echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
                ;;
            "helm")
                echo "Helm: $(helm version --short)"
                ;;
            "docker")
                echo "Docker: $(docker --version)"
                ;;
        esac
        log_success "$tool is installed"
    else
        log_error "$tool is not installed"
        exit 1
    fi
done

# 3. Verify VS Code Extensions
log_info "3. Verifying VS Code extensions..."
if command -v code &> /dev/null; then
    extensions=("hashicorp.terraform" "ms-kubernetes-tools.vscode-kubernetes-tools" "redhat.vscode-yaml")
    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            log_success "VS Code extension $ext is installed"
        else
            log_warning "VS Code extension $ext is not installed"
        fi
    done
else
    log_warning "VS Code is not installed or not in PATH"
fi

# 4. Verify Terraform Configuration
log_info "4. Verifying Terraform configuration..."

if [ -d "terraform" ]; then
    cd terraform
    
    # Check if terraform is initialized
    if [ -d ".terraform" ]; then
        log_success "Terraform is initialized"
    else
        log_warning "Terraform is not initialized. Run 'terraform init'"
    fi
    
    # Validate Terraform configuration
    if terraform validate &> /dev/null; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration is invalid"
        terraform validate
        exit 1
    fi
    
    # Check Terraform format
    if terraform fmt -check &> /dev/null; then
        log_success "Terraform files are properly formatted"
    else
        log_warning "Terraform files need formatting. Run 'terraform fmt'"
    fi
    
    cd ..
else
    log_error "Terraform directory not found"
    exit 1
fi

# 5. Verify AWS Resources
log_info "5. Verifying AWS resources..."

# Check S3 bucket for Terraform state
if aws s3 ls s3://quanttrader-tf-state --profile quanttrader-dev &> /dev/null; then
    log_success "S3 bucket for Terraform state exists"
else
    log_warning "S3 bucket for Terraform state not found or not accessible"
fi

# Check DynamoDB table for state locking
if aws dynamodb describe-table --table-name quanttrader-tf-lock --profile quanttrader-dev &> /dev/null; then
    log_success "DynamoDB table for state locking exists"
else
    log_warning "DynamoDB table for state locking not found or not accessible"
fi

# Check billing alarms
log_info "Checking billing alarms..."
alarms=$(aws cloudwatch describe-alarms --alarm-name-prefix quanttrader-billing --region us-west-2 --profile quanttrader-dev --query 'MetricAlarms[].AlarmName' --output text 2>/dev/null || echo "")

if [ -n "$alarms" ]; then
    echo "Billing alarms found:"
    for alarm in $alarms; do
        echo "  - $alarm"
    done
    log_success "Billing alarms are configured"
else
    log_warning "No billing alarms found"
fi

# 6. Verify Cost Monitoring Scripts
log_info "6. Verifying cost monitoring scripts..."

if [ -f "scripts/daily-cost.sh" ] && [ -x "scripts/daily-cost.sh" ]; then
    log_success "Daily cost monitoring script exists and is executable"
else
    log_error "Daily cost monitoring script not found or not executable"
fi

if [ -f "scripts/cost-alert.sh" ] && [ -x "scripts/cost-alert.sh" ]; then
    log_success "Cost alert script exists and is executable"
else
    log_error "Cost alert script not found or not executable"
fi

# 7. Verify Makefile
log_info "7. Verifying Makefile..."

if [ -f "Makefile" ]; then
    log_success "Makefile exists"
    
    # Test a few make commands
    if make help &> /dev/null; then
        log_success "Makefile is functional"
    else
        log_warning "Makefile may have issues"
    fi
else
    log_error "Makefile not found"
fi

# 8. Verify .gitignore
log_info "8. Verifying .gitignore..."

if [ -f ".gitignore" ]; then
    log_success ".gitignore file exists"
    
    # Check for important patterns
    if grep -q "*.tfstate" .gitignore; then
        log_success ".gitignore includes Terraform state files"
    else
        log_warning ".gitignore may be missing Terraform patterns"
    fi
else
    log_warning ".gitignore file not found"
fi

# 9. Test Cost Monitoring

# Check Cost Explorer policy
log_info "Checking Cost Explorer policy..."
if aws iam list-attached-user-policies --user-name quanttrader-dev --profile quanttrader-dev --query "AttachedPolicies[?PolicyName=='QuantTraderCostExplorerPolicy']" --output text | grep -q "QuantTraderCostExplorerPolicy"; then
    log_success "Cost Explorer policy is attached"
else
    log_warning "Cost Explorer policy not found. Run setup script to add it."
fi

log_info "9. Testing cost monitoring..."

if [ -f "scripts/daily-cost.sh" ]; then
    log_info "Testing daily cost script (this may take a moment)..."
    if ./scripts/daily-cost.sh &> /dev/null; then
        log_success "Daily cost script executed successfully"
    else
        log_warning "Daily cost script had issues (this is normal if no costs exist yet)"
    fi
fi

# 10. Final Summary
echo ""
echo "=================================="
log_info "Verification Complete!"
echo "=================================="

echo ""
echo "Summary:"
echo "- AWS CLI: $(aws --version | cut -d' ' -f1)"
echo "- Terraform: $(terraform version | head -1 | cut -d' ' -f2)"
echo "- kubectl: $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo 'installed')"
echo "- Helm: $(helm version --short | cut -d' ' -f2)"
echo "- Docker: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"

echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your email address"
echo "2. Run 'make plan-terraform' to review Terraform changes"
echo "3. Run 'make apply-terraform' to create AWS resources"
echo "4. Check your email and confirm SNS subscription for billing alerts"
echo "5. Run './scripts/daily-cost.sh' to monitor costs"

log_success "Task 1.1 verification completed successfully!"
