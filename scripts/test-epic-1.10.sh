#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

info "Epic 1.10 External Secrets verification"
[ -d gitops/shared ] && ok "shared dir present (for ESO manifests)" || { err "shared missing"; exit 1; }
[ -f docs/secrets.md ] && ok "docs/secrets.md present" || { err "docs/secrets.md missing"; exit 1; }
ok "Epic 1.10 checks passed" 