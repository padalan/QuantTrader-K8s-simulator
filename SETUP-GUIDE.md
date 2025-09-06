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
make init-terraform
```

4) Configure variables
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# set billing_email and monthly_budget
```

5) Apply Terraform
```bash
make apply-terraform
```

### Verification
```bash
./scripts/verify-1.1.sh
```

### Cost Monitoring
```bash
make check-costs
# or
./scripts/daily-cost.sh
```

## What Gets Created

- S3 bucket for Terraform state (encrypted)
- DynamoDB table for state locking
- CloudWatch billing alarms at 40/60/80/100% of monthly_budget
- SNS topic + subscription for billing notifications

## Versions

- AWS CLI 2.28+
- Terraform 1.5+
- kubectl 1.27+
- Helm 3.10+
- Docker 20+

## Troubleshooting

- `chmod +x scripts/*.sh`
- `aws configure --profile quanttrader-dev`
- `cd terraform && terraform init`
- See `AWS-PERMISSIONS.md`

## Next Steps

- Use `make hobby-start` to practice Kubernetes locally with Kind
- When comfortable, plan Phase 2 (introduce cloud Kubernetes, GitOps, observability)
