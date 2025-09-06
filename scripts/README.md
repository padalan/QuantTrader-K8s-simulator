# QuantTrader-K8s-Simulator Scripts

This directory contains automation scripts for the QuantTrader-K8s-Simulator project.

## Setup Scripts

### setup-1.1.sh
Purpose: Complete setup for Phase 1 (tools, AWS profile, Terraform backend, billing alarms)

Usage:
```bash
./scripts/setup-1.1.sh
```

### verify-1.1.sh
Purpose: Verification of setup

Usage:
```bash
./scripts/verify-1.1.sh
```

### check-prerequisites-simple.sh
Purpose: Fast, non-interactive prerequisite checks for macOS and required tools

Usage:
```bash
make check-prerequisites
# or
./scripts/check-prerequisites-simple.sh
```

## Cost Monitoring

### daily-cost.sh
Shows yesterday's and monthly costs (Cost Explorer)

Usage:
```bash
./scripts/daily-cost.sh
```

### cost-alert.sh
Monitors daily costs against a threshold; optional.

Usage:
```bash
./scripts/cost-alert.sh
```

## Makefile Commands

```bash
make help              # Show all commands
make check-prerequisites
make install-tools
make setup-aws
make init-terraform
make plan-terraform
make apply-terraform
make destroy-terraform
make validate-terraform
make format-terraform
make check-costs
make hobby-start
make hobby-stop
make phase-upgrade-check
make clean | clean-repo | clean-cache
```

## Notes

- Prefer `check-prerequisites-simple.sh` for hobby setup
- Terraform variables: set `billing_email` and optionally `monthly_budget`
- Cost Explorer must be enabled in your AWS account
