#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

info "Epic 1.6 CI/CD verification"
[ -f .github/workflows/terraform-plan.yml ] && ok "terraform-plan workflow present" || { err "missing plan workflow"; exit 1; }
[ -f .github/workflows/terraform-apply.yml ] && ok "terraform-apply workflow present" || { err "missing apply workflow"; exit 1; }
[ -f CODEOWNERS ] && ok "CODEOWNERS present" || { err "CODEOWNERS missing"; exit 1; }
[ -f .github/ISSUE_TEMPLATE/bug.md ] && ok "bug issue template present" || { err "bug template missing"; exit 1; }
[ -f .github/ISSUE_TEMPLATE/feature_request.md ] && ok "feature template present" || { err "feature template missing"; exit 1; }
[ -f .github/PULL_REQUEST_TEMPLATE.md ] && ok "PR template present" || { err "PR template missing"; exit 1; }
ok "Epic 1.6 checks passed" 