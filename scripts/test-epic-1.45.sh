#!/usr/bin/env bash
# test-epic-1.45.sh | Validate VPC & Networking configuration
# QuantTrader-K8s-Simulator Phase 1 - Epic 1.45

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

log_info "Starting Epic 1.45 Validation"
echo "=================================="

cd terraform/environments/dev

# 1) VPC exists with correct CIDR
log_info "1. Checking VPC outputs and CIDR..."
VPC_ID=$(terraform output -raw vpc_id || true)
VPC_CIDR=$(terraform output -raw vpc_cidr_block || true)
if [ -z "$VPC_ID" ]; then
  log_error "VPC ID not found. Apply first: make env-dev-apply"
  exit 1
fi
aws_vpc_cidr=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].CidrBlock' --output text)
if [ "$aws_vpc_cidr" = "$VPC_CIDR" ]; then
  log_success "VPC CIDR matches: $aws_vpc_cidr"
else
  log_error "VPC CIDR mismatch: TF=$VPC_CIDR AWS=$aws_vpc_cidr"
  exit 1
fi

# 2) Two public and two private subnets
log_info "2. Checking subnets..."
PUB_CNT=$(python3 -c 'import json,sys; print(len(json.loads(sys.stdin.read())))' <<< "$(terraform output -json public_subnet_ids)")
PRV_CNT=$(python3 -c 'import json,sys; print(len(json.loads(sys.stdin.read())))' <<< "$(terraform output -json private_subnet_ids)")
[ "$PUB_CNT" -eq 2 ] && log_success "Two public subnets" || { log_error "Expected 2 public, found $PUB_CNT"; exit 1; }
[ "$PRV_CNT" -eq 2 ] && log_success "Two private subnets" || { log_error "Expected 2 private, found $PRV_CNT"; exit 1; }

# 3) IGW attached
log_info "3. Checking IGW attachment..."
IGW_ID=$(terraform output -raw internet_gateway_id)
aws ec2 describe-internet-gateways --internet-gateway-ids "$IGW_ID" --query 'InternetGateways[0].Attachments[0].VpcId' --output text | grep -q "$VPC_ID" && \
  log_success "IGW $IGW_ID attached to VPC" || { log_error "IGW not attached to VPC"; exit 1; }

# 4) Public routes to IGW
log_info "4. Validating public route tables default route to IGW..."
CNT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID   --query "length(RouteTables[].Routes[?DestinationCidrBlock=='0.0.0.0/0' && GatewayId=='$IGW_ID'])" --output text)
[ "$CNT" != "None" ] && [ $CNT -ge 1 ] && log_success "Public route to IGW verified" || { log_error "Public route to IGW missing"; exit 1; }

# 5) If NAT enabled, check NATs and private routes
EN_NAT=$(grep -E '^enable_nat_gateway' terraform.tfvars | awk -F'=' '{print $2}' | tr -d ' "') || EN_NAT="false"
if [ "$EN_NAT" = "true" ]; then
  log_info "5. NAT enabled, validating NAT and private routes..."
  NAT_ID=$(terraform output -raw nat_gateway_id)
  if [ "$NAT_ID" = "null" ] || [ -z "$NAT_ID" ]; then
    log_error "NAT expected but not found in outputs"
    exit 1
  fi
  CNTN=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID     --query "length(RouteTables[].Routes[?DestinationCidrBlock=='0.0.0.0/0' && NatGatewayId=='$NAT_ID'])" --output text)
  [ "$CNTN" != "None" ] && [ $CNTN -ge 1 ] && log_success "Private route to NAT verified" || { log_error "Private route to NAT missing"; exit 1; }
else
  log_info "5. NAT disabled; skipping NAT checks"
fi

# 6) Security groups existence (basic)
log_info "6. Checking security groups..."
SG_CP=$(terraform output -raw eks_cluster_security_group_id)
SG_NODES=$(terraform output -raw eks_nodes_security_group_id)
[ -n "$SG_CP" ] && log_success "Control plane SG present: $SG_CP" || { log_error "Missing control plane SG"; exit 1; }
[ -n "$SG_NODES" ] && log_success "Nodes SG present: $SG_NODES" || { log_error "Missing nodes SG"; exit 1; }

log_info "Validation Complete!"
echo "=================================="
log_success "Epic 1.45 validation completed successfully!"
