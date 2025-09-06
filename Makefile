# QuantTrader-K8s-Simulator Makefile

export AWS_PROFILE ?= quanttrader-dev
export AWS_DEFAULT_REGION ?= us-west-2
export TF_IN_AUTOMATION ?= 1

.PHONY: help install-tools setup-aws init-terraform plan-terraform apply-terraform destroy-terraform check-costs

help: ## Show this help message
	@echo "QuantTrader-K8s-Simulator - Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install-tools: ## Install required development tools
	@echo "Installing development tools..."
	brew install awscli terraform kubectl helm docker
	@echo "Installing VS Code extensions..."
	@for ext in hashicorp.terraform ms-kubernetes-tools.vscode-kubernetes-tools redhat.vscode-yaml; do \
		echo "Installing $$ext..."; \
		code --install-extension $$ext 2>/dev/null || echo "Extension $$ext installation failed or already installed"; \
	done

setup-aws: ## Configure AWS CLI profile
	@echo "Configuring AWS profile..."
	aws configure set region us-west-2 --profile quanttrader-dev
	aws configure set output json --profile quanttrader-dev
	@echo "Please run: aws configure --profile quanttrader-dev"

init-terraform: ## Initialize Terraform
	cd terraform && terraform init

plan-terraform: ## Plan Terraform changes
	cd terraform && terraform plan

apply-terraform: ## Apply Terraform changes
	cd terraform && terraform apply

destroy-terraform: ## Destroy Terraform resources
	cd terraform && terraform destroy

check-costs: ## Check daily costs
	./scripts/daily-cost.sh

validate-terraform: ## Validate Terraform configuration
	cd terraform && terraform validate && terraform fmt -check

format-terraform: ## Format Terraform files
	cd terraform && terraform fmt -recursive

clean-cache: ## Clean Terraform cache and temporary files
	@echo "Cleaning Terraform cache..."
	rm -rf terraform/.terraform
	rm -rf terraform/.terraform.lock.hcl
	@echo "Cleaning temporary files..."
	rm -f terraform/terraform.tfstate.backup
	rm -f terraform/terraform.tfstate
	@echo "Cache cleaned!"

clean-repo: ## Clean repository (cache + ephemeral docs)
	@echo "Cleaning repository..."
	rm -rf terraform/.terraform
	rm -rf terraform/.terraform.lock.hcl
	rm -f terraform/terraform.tfstate.backup
	rm -f terraform/terraform.tfstate
	@echo "Removing ephemeral documentation..."
	rm -f FIXES-SUMMARY.md
	rm -f TERRAFORM-FIXES.md
	rm -f SETUP-SCRIPT-FIXES.md
	rm -f TASK-1.1-COMPLETION.md
	rm -f PHASE-1.1-SUMMARY.md
	rm -f COST-EXPLORER-INTEGRATION.md
	rm -f IDEMPOTENCY-REVIEW.md
	rm -f IMPROVEMENTS-SUMMARY.md
	@echo "Repository cleaned!"

clean: clean-repo ## Clean everything (cache + ephemeral docs + temp files)
	@echo "Cleaning everything..."
	rm -f *.log
	rm -f *.tmp
	rm -f .DS_Store
	rm -rf .vscode/settings.json.bak
	@echo "Everything cleaned!"


terraform-init-all: ## Initialize all environments
	cd terraform && terraform init || true
	cd terraform/environments/dev && AWS_PROFILE=$(AWS_PROFILE) terraform init || true

terraform-plan-all: ## Plan all environments
	cd terraform && terraform plan || true
	cd terraform/environments/dev && terraform plan || true

terraform-lint: ## Run terraform linting
	cd terraform && tflint --recursive || true

terraform-docs: ## Generate Terraform docs
	cd terraform && terraform-docs markdown table --output-file README.md . || true


test-epic-1.2: ## Test Epic 1.2 implementation
	./scripts/test-epic-1.2.sh
	./scripts/test-epic-1.5.sh

test-all: ## Run all available tests
	@echo "Running comprehensive test suite..."
	./scripts/check-prerequisites-simple.sh
	./scripts/test-epic-1.2.sh
	./scripts/test-epic-1.5.sh
	@echo "All tests completed!"


env-dev-init: ## Initialize Terraform in environments/dev
	AWS_PROFILE=$(AWS_PROFILE) ./scripts/terraform-env.sh dev init

env-dev-validate: ## Validate Terraform in environments/dev
	AWS_PROFILE=$(AWS_PROFILE) ./scripts/terraform-env.sh dev validate

env-dev-plan: ## Plan Terraform in environments/dev
	AWS_PROFILE=$(AWS_PROFILE) ./scripts/terraform-env.sh dev plan

env-dev-apply: ## Apply Terraform in environments/dev
	AWS_PROFILE=$(AWS_PROFILE) ./scripts/terraform-env.sh dev apply

env-dev-destroy: ## Destroy Terraform in environments/dev
	AWS_PROFILE=$(AWS_PROFILE) ./scripts/terraform-env.sh dev destroy

test-epic-1.3: ## Run Epic 1.3 test suite
	./scripts/test-epic-1.3.sh

test-epic-1.5: ## Validate VPC & Networking configuration
	./scripts/test-epic-1.5.sh

# Hobby mode targets for local development
hobby-start: ## Start hobby-mode infrastructure (local Kind + minimal AWS)
	@echo "🏠 Starting hobby infrastructure (local + minimal AWS)"
	@echo "Checking Docker daemon..."
	@until docker info >/dev/null 2>&1; do \
		echo "Waiting for Docker daemon to start..."; \
		sleep 2; \
	done
	@echo "Creating Kind cluster..."
	kind create cluster --config local/kind-config.yaml || echo "Kind cluster may already exist"
	@echo "Starting minimal AWS resources..."
	cd terraform && terraform init -reconfigure && terraform apply -var="deployment_mode=local" -auto-approve || echo "AWS resources may already exist"

hobby-stop: ## Stop and save costs
	@echo "💰 Stopping infrastructure to save costs"
	kind delete cluster || echo "Kind cluster not found"
	cd terraform && terraform init -reconfigure && terraform destroy -auto-approve || echo "No AWS resources to destroy"

phase-upgrade-check: ## Check if ready for next phase
	@echo "🎯 Phase upgrade readiness:"
	@./scripts/phase-check.sh

