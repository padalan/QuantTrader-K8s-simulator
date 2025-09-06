# QuantTrader-K8s-Simulator

```
Educational purpose only. This project follows a "learning-first, cost-conscious" approach rather than a production-heavy setup.
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.27%2B-blue.svg)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-Billing%20%26%20S3-orange.svg)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-purple.svg)](https://terraform.io/)

> A learning-first trading platform simulator. Focused on fundamentals, automation, and cost awareness for a hobby project.

## Overview

QuantTrader-K8s-Simulator demonstrates a lean, learning-first setup: Terraform-managed AWS billing alerts and backends, plus an optional local Kubernetes cluster via Kind. Start local, learn fast, and scale complexity later. 

### Key Features

- **Lean by default**: Minimal AWS resources (S3 + DynamoDB + Billing alarms)
- **Local-first**: Optional Kind cluster for Kubernetes learning at zero cost
- **Cost awareness**: Daily cost script and dynamic billing thresholds
- **IaC**: Simple Terraform with S3 backend and DynamoDB state locking

## Quick Start

### Prerequisites

- macOS 12+
- Homebrew
- AWS account with billing enabled
- Tools: AWS CLI 2.28+, Terraform 1.5+, kubectl 1.27+, Helm 3.10+, Docker 20+

Run the automated checks:

```bash
make check-prerequisites
```

### Setup

1) Configure AWS profile (once):
```bash
make setup-aws
aws configure --profile quanttrader-dev
```

2) Initialize Terraform backend:
```bash
make init-terraform
```

3) Set your email and optional budget:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit terraform/terraform.tfvars
# billing_email = "you@example.com"
# monthly_budget = 50
```

4) Apply minimal AWS resources (S3 backend, DynamoDB lock, billing alarms):
```bash
make apply-terraform
```

### Optional: Local Kubernetes with Kind
```bash
make hobby-start   # creates local Kind cluster
# ...practice kubectl and Helm locally...
make hobby-stop    # deletes the cluster
```

## Configuration

- `terraform/backend.tf`: Remote state in S3 with DynamoDB lock
- `terraform/variables.tf`: `billing_email`, `monthly_budget`, `deployment_mode`
- `terraform/billing.tf`: Billing alarms at 40%, 60%, 80%, 100% of `monthly_budget`
- `local/kind-config.yaml`: Kind cluster config

## Cost Monitoring

- Daily costs by service:
```bash
./scripts/daily-cost.sh
```
- CloudWatch billing alarms are created dynamically from `monthly_budget`.

## Makefile Commands

```bash
make help
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

- This repo intentionally avoids EKS/ArgoCD in Phase 1 to keep costs and complexity low.
- Upgrade paths (EKS, GitOps, observability) can be added in later phases.

## License

This project is licensed under the MIT License - see the `LICENSE` file.

## Sprint 1 Consolidation

- Terraform consolidated to root with modules for backend, billing, and VPC
- Single active environment: `environments/dev` (staging/prod pruned as placeholders)
- New parameterized Terraform runner: `./scripts/terraform-env.sh <env> <action>`
- VPC validation test: `make test-epic-1.45`

### Useful commands

- `make env-dev-init` / `make env-dev-plan` / `make env-dev-apply`
- `./scripts/terraform-env.sh dev apply` (parameterized)
- `make test-all` and `make test-epic-1.45`

