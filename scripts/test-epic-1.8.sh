#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

info "Epic 1.8 GitOps structure verification"
[ -d gitops/applications ] && ok "applications dir present" || { err "applications missing"; exit 1; }
[ -d gitops/environments/dev ] && ok "dev overlay present" || { err "dev env missing"; exit 1; }
[ -d gitops/environments/staging ] && ok "staging overlay present" || { err "staging env missing"; exit 1; }
[ -d gitops/environments/prod ] && ok "prod overlay present" || { err "prod env missing"; exit 1; }
[ -d gitops/shared ] && ok "shared dir present" || { err "shared missing"; exit 1; }
ok "Epic 1.8 checks passed" 