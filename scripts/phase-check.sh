#!/usr/bin/env bash
set -euo pipefail

check() {
  if "$@" >/dev/null 2>&1; then echo "✅ $*"; else echo "❌ $*"; fi
}

echo "🎯 Phase 1 Completion Checklist"
echo "================================"
check kubectl version --client
check terraform version
check kind version

echo "\n📚 Learning Validation (self-assess):"
echo "1. Can you explain Kubernetes pods? [y/n]"
echo "2. Understand Terraform state? [y/n]"
echo "3. Familiar with container basics? [y/n]"
