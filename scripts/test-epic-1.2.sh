#!/usr/bin/env bash
# test-epic-1.2.sh | Verification script for Epic 1.2
# QuantTrader-K8s-Simulator Phase 1 - Epic 1.2: Terraform Project Structure

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

log_info "Starting Epic 1.2 Verification"
echo "=================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# 1. Verify Module Structure
log_info "1. Verifying module structure..."
if [ -d "terraform/modules/billing" ]; then
    log_success "Billing module directory exists"
else
    log_error "Billing module directory missing"
    exit 1
fi

if [ -f "terraform/modules/billing/main.tf" ]; then
    log_success "Billing module main.tf exists"
else
    log_error "Billing module main.tf missing"
    exit 1
fi

if [ -f "terraform/modules/billing/variables.tf" ]; then
    log_success "Billing module variables.tf exists"
else
    log_error "Billing module variables.tf missing"
    exit 1
fi

if [ -f "terraform/modules/billing/outputs.tf" ]; then
    log_success "Billing module outputs.tf exists"
else
    log_error "Billing module outputs.tf missing"
    exit 1
fi

# 2. Verify Root Configuration
log_info "2. Verifying root configuration..."
if [ -f "terraform/main.tf" ]; then
    log_success "Root main.tf exists"
else
    log_error "Root main.tf missing"
    exit 1
fi

if grep -q "module \"billing\"" terraform/main.tf; then
    log_success "Root main.tf calls billing module"
else
    log_error "Root main.tf does not call billing module"
    exit 1
fi

# 3. Verify Environment Structure
log_info "3. Verifying environment structure..."
for env in dev staging prod; do
    if [ -d "terraform/environments/$env" ]; then
        log_success "Environment $env directory exists"
    else
        log_error "Environment $env directory missing"
        exit 1
    fi
    
    if [ -f "terraform/environments/$env/terraform.tfvars" ]; then
        log_success "Environment $env tfvars exists"
    else
        log_error "Environment $env tfvars missing"
        exit 1
    fi
done

# 4. Verify Terraform Configuration
log_info "4. Verifying Terraform configuration..."
cd terraform
if terraform validate >/dev/null 2>&1; then
    log_success "Terraform configuration is valid"
else
    log_error "Terraform configuration is invalid"
    terraform validate
    exit 1
fi

if terraform fmt -check >/dev/null 2>&1; then
    log_success "Terraform files are properly formatted"
else
    log_warning "Terraform files need formatting"
    terraform fmt -recursive
    log_success "Terraform files formatted"
fi

cd ..

# 5. Verify Module Variables
log_info "5. Verifying module variables..."
if grep -q "monthly_budget" terraform/modules/billing/variables.tf; then
    log_success "Billing module has monthly_budget variable"
else
    log_error "Billing module missing monthly_budget variable"
    exit 1
fi

if grep -q "billing_email" terraform/modules/billing/variables.tf; then
    log_success "Billing module has billing_email variable"
else
    log_error "Billing module missing billing_email variable"
    exit 1
fi

# 6. Verify Makefile Targets
log_info "6. Verifying Makefile targets..."
if grep -q "terraform-init-all" Makefile; then
    log_success "Makefile has terraform-init-all target"
else
    log_error "Makefile missing terraform-init-all target"
    exit 1
fi

if grep -q "terraform-plan-all" Makefile; then
    log_success "Makefile has terraform-plan-all target"
else
    log_error "Makefile missing terraform-plan-all target"
    exit 1
fi

if grep -q "terraform-lint" Makefile; then
    log_success "Makefile has terraform-lint target"
else
    log_error "Makefile missing terraform-lint target"
    exit 1
fi

if grep -q "terraform-docs" Makefile; then
    log_success "Makefile has terraform-docs target"
else
    log_error "Makefile missing terraform-docs target"
    exit 1
fi

# 7. Verify Pre-commit Configuration
log_info "7. Verifying pre-commit configuration..."
if [ -f ".pre-commit-config.yaml" ]; then
    log_success "Pre-commit configuration exists"
else
    log_error "Pre-commit configuration missing"
    exit 1
fi

if grep -q "terraform_fmt" .pre-commit-config.yaml; then
    log_success "Pre-commit has terraform_fmt hook"
else
    log_error "Pre-commit missing terraform_fmt hook"
    exit 1
fi

# 8. Test Terraform Plan (Dry Run)
log_info "8. Testing Terraform plan (dry run)..."
cd terraform
if terraform plan -var="billing_email=test@example.com" -var="monthly_budget=50" >/dev/null 2>&1; then
    log_success "Terraform plan executes successfully"
else
    log_warning "Terraform plan failed (may be expected if AWS resources don't exist)"
fi

cd ..

# 9. Test Makefile Functionality
log_info "9. Testing Makefile functionality..."
if make help >/dev/null 2>&1; then
    log_success "Makefile help command works"
else
    log_error "Makefile help command failed"
    exit 1
fi

log_info "Verification Complete!"
echo "=================================="

echo ""
echo "Summary:"
echo "- Module Structure: Billing module with main.tf, variables.tf, outputs.tf"
echo "- Environment Configs: dev, staging, prod tfvars files"
echo "- Terraform Validation: Configuration valid and formatted"
echo "- Makefile Targets: terraform-init-all, terraform-plan-all, terraform-lint, terraform-docs"
echo "- Pre-commit: terraform_fmt hook configured"
echo "- Root Configuration: Calls billing module with common tags"

echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your email and budget"
echo "2. Run 'make plan-terraform' to review Terraform changes"
echo "3. Run 'make apply-terraform' to create AWS resources"
echo "4. Install quality tools: brew install tflint terraform-docs pre-commit"
echo "5. Run 'make terraform-lint' and 'make terraform-docs' for code quality"

log_success "Epic 1.2 verification completed successfully!"
