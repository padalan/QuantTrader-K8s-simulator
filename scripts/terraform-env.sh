#!/usr/bin/env bash
# terraform-env.sh | Manage Terraform for a given environment
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <env> <action> [extra args]"
  echo "Actions: init|validate|plan|apply|destroy"
  exit 1
fi

ENV="$1"; ACTION="$2"; shift 2
DIR="terraform/environments/$ENV"
if [ ! -d "$DIR" ]; then
  echo "Environment directory not found: $DIR" >&2
  exit 1
fi

case "$ACTION" in
  init)
    (cd "$DIR" && terraform init)
    ;;
  validate)
    (cd "$DIR" && terraform validate)
    ;;
  plan)
    (cd "$DIR" && terraform plan -var-file="terraform.tfvars" "$@")
    ;;
  apply)
    (cd "$DIR" && terraform apply -auto-approve -var-file="terraform.tfvars" "$@")
    ;;
  destroy)
    (cd "$DIR" && terraform destroy -auto-approve -var-file="terraform.tfvars" "$@")
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
 esac 