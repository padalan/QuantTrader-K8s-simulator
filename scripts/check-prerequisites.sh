#!/usr/bin/env bash
# Unified prerequisites checker; use --ci for non-interactive minimal output
set -euo pipefail
CI_MODE=false
[ "${1:-}" = "--ci" ] && CI_MODE=true

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log(){ $CI_MODE && echo "$1" || echo -e "$1"; }
ok(){ log "${GREEN}[SUCCESS]${NC} $1"; }
info(){ log "${BLUE}[INFO]${NC} $1"; }
warn(){ log "${YELLOW}[WARNING]${NC} $1"; }
err(){ log "${RED}[ERROR]${NC} $1"; }

info "QuantTrader-K8s-Simulator Prerequisites Check"
echo "=============================================="

# OS
info "1. Checking operating system..."
if [[ "$OSTYPE" == darwin* ]]; then ok "macOS detected"; else err "macOS required"; exit 1; fi

# Resources
info "2. Checking system resources..."
MEM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
[ $MEM_GB -ge 8 ] && ok "Memory: ${MEM_GB}GB (>=8GB)" || { err "Insufficient memory"; exit 1; }

# Tools
info "3. Checking required tools..."
command -v aws >/dev/null && ok "AWS CLI: $(aws --version | head -1)" || { err "AWS CLI missing"; exit 1; }
command -v terraform >/dev/null && ok "Terraform: $(terraform version | head -1)" || { err "Terraform missing"; exit 1; }
command -v kubectl >/dev/null && ok "kubectl: $(kubectl version --client --short 2>/dev/null | head -1)" || warn "kubectl not found"
command -v helm >/dev/null && ok "Helm: $(helm version --short)" || warn "Helm not found"
command -v docker >/dev/null && ok "Docker: $(docker --version)" || warn "Docker not found"
command -v kind >/dev/null && ok "Kind: $(kind version)" || warn "Kind not found"

# Network
info "4. Checking network connectivity..."
curl -s --max-time 10 https://aws.amazon.com >/dev/null && ok "Internet connectivity verified" || { err "No internet"; exit 1; }

# AWS creds
info "5. Checking AWS credentials..."
if aws sts get-caller-identity --profile quanttrader-dev >/dev/null 2>&1; then
  ACCT=$(aws sts get-caller-identity --query Account --output text --profile quanttrader-dev)
  ok "AWS profile quanttrader-dev ok (acct: $ACCT)"
else
  warn "Configure: aws configure --profile quanttrader-dev"
fi

ok "Prerequisites check completed!"
