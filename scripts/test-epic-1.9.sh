#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

info "Epic 1.9 Helm charts verification"
[ -d charts/base-microservice ] && ok "base-microservice chart present" || { err "chart missing"; exit 1; }
[ -f charts/base-microservice/Chart.yaml ] && ok "Chart.yaml present" || { err "Chart.yaml missing"; exit 1; }
[ -f charts/base-microservice/values.yaml ] && ok "values.yaml present" || { err "values.yaml missing"; exit 1; }
[ -f charts/base-microservice/values/dev.yaml ] && ok "dev.yaml present" || { err "dev.yaml missing"; exit 1; }
[ -f charts/base-microservice/values/staging.yaml ] && ok "staging.yaml present" || { err "staging.yaml missing"; exit 1; }
[ -f charts/base-microservice/values/prod.yaml ] && ok "prod.yaml present" || { err "prod.yaml missing"; exit 1; }
ok "Epic 1.9 checks passed" 