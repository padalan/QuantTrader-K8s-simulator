# QuantTrader-K8s-Simulator Setup Guide

## Quick Start

This guide sets up the lean Phase 1 environment.

### Prerequisites

- macOS (12+)
- Homebrew installed
- AWS account with programmatic access
- See `AWS-PERMISSIONS.md` for required permissions

Run checks:
```bash
make check-prerequisites
```

### One-Command Setup

```bash
./scripts/setup-1.1.sh
```
What it does:
- Installs tools (AWS CLI, Terraform, kubectl, Helm, Docker)
- Configures AWS CLI profile
- Writes Terraform backend
- Sets up billing alarms and cost scripts
- Creates Makefile commands

### Manual Setup (Alternative)

1) Install tools
```bash
make install-tools
```

2) Configure AWS CLI
```bash
make setup-aws
aws configure --profile quanttrader-dev
```

3) Initialize Terraform
```bash
make env-dev-init
```

4) Configure variables
```bash
cp terraform/environments/dev/terraform.tfvars terraform/environments/dev/terraform.tfvars
# adjust as needed
```

5) Apply Terraform
```bash
make env-dev-apply
```

6) Validate VPC & Networking
```bash
make test-epic-1.45
```

## Troubleshooting

- `chmod +x scripts/*.sh`
- `aws configure --profile quanttrader-dev`
- `./scripts/terraform-env.sh dev init`
- See `AWS-PERMISSIONS.md`

## Next Steps

- Use `make hobby-start` to practice Kubernetes locally with Kind
- When comfortable, plan Phase 2 (introduce cloud Kubernetes, GitOps, observability)
