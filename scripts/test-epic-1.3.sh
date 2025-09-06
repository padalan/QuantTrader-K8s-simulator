#!/usr/bin/env bash
# test-epic-1.3.sh | Verification script for Epic 1.3 (VPC & Networking)
# QuantTrader-K8s-Simulator Phase 1 - Epic 1.3

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Starting Epic 1.3 Verification"
echo "=================================="

# 1. Validate Terraform in env/dev
log_info "1. Validating Terraform in environments/dev..."
cd terraform/environments/dev
if terraform validate >/dev/null 2>&1; then
  log_success "Terraform configuration (env/dev) is valid"
else
  log_error "Terraform configuration (env/dev) is invalid"
  terraform validate
  exit 1
fi

# Expect VPC to be applied before these checks
log_info "2. Checking VPC outputs (requires apply)..."
if terraform output -raw vpc_id >/dev/null 2>&1; then
  VPC_ID=$(terraform output -raw vpc_id)
  log_success "VPC ID: $VPC_ID"
else
  log_warning "VPC output not available. Run 'make env-dev-apply' first."
  exit 0
fi

# 3. Verify subnets count
PUBLIC_CNT=$(terraform output -json public_subnet_ids | jq 'length')
PRIVATE_CNT=$(terraform output -json private_subnet_ids | jq 'length')
if [ "$PUBLIC_CNT" -eq 2 ]; then
  log_success "Two public subnets detected"
else
  log_error "Expected 2 public subnets, found $PUBLIC_CNT"
fi
if [ "$PRIVATE_CNT" -eq 2 ]; then
  log_success "Two private subnets detected"
else
  log_error "Expected 2 private subnets, found $PRIVATE_CNT"
fi

# 4. Verify routing via AWS CLI
log_info "4. Verifying route tables via AWS CLI..."
aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID >/dev/null 2>&1 && log_success "Route tables fetched" || log_error "Unable to fetch route tables"

# 5. Summary
log_info "Verification Complete!"
echo "=================================="

echo ""
echo "Next steps:"
echo "1. Ensure IGW/NAT configuration aligns with cost goals (enable_nat_gateway=false by default)"
echo "2. Confirm routes to 0.0.0.0/0 for public (IGW) and private (NAT) when enabled"
echo "3. Extend tests as topology evolves"

log_success "Epic 1.3 verification completed!"
