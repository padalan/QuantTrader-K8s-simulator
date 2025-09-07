#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <from_env> <to_env>"
  exit 1
fi
FROM=$1; TO=$2

BR_FROM="env/${FROM}"; BR_TO="env/${TO}"

git fetch origin

git checkout "$BR_TO"
git merge --no-ff --no-edit "origin/$BR_FROM" || {
  echo "Merge conflicts. Resolve manually."; exit 1;
}

git push origin "$BR_TO"
echo "Promoted $FROM -> $TO" 