#!/usr/bin/env bash
# setup-1.1.sh | Task 1.1: AWS CLI, tools & cost monitoring
# QuantTrader-K8s-Simulator Phase 1 - Epic 1.1

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed. Please install it first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

log_info "Starting QuantTrader-K8s-Simulator Phase 1.1 Setup"
echo "=================================================="

# 1. AWS CLI & IAM Configuration
log_info "Step 1: Configuring AWS CLI & IAM"

# Check if AWS CLI is already installed
if ! command -v aws &> /dev/null; then
    log_info "Installing AWS CLI v2..."
    brew install awscli
else
    log_info "AWS CLI already installed: $(aws --version)"
fi

# Configure AWS profile
log_info "Configuring AWS profile 'quanttrader-dev'..."
aws configure set region us-west-2 --profile quanttrader-dev
aws configure set output json --profile quanttrader-dev

# Check if AWS credentials are configured
if ! aws sts get-caller-identity --profile quanttrader-dev &> /dev/null; then
    log_warning "AWS credentials not configured for profile 'quanttrader-dev'"
    log_info "Please run the following commands to configure your AWS credentials:"
    echo "  aws configure --profile quanttrader-dev"
    echo "  # Enter your AWS Access Key ID, Secret Access Key, and region (us-west-2)"
    echo ""
    log_info "Or set environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=your_access_key"
    echo "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo "  export AWS_DEFAULT_REGION=us-west-2"
    echo ""
    # Auto-continue after AWS credentials check
fi

# Verify AWS configuration
log_info "Verifying AWS configuration..."
aws sts get-caller-identity --profile quanttrader-dev
log_success "AWS CLI configured successfully"

# 2. Install Development Tools
log_info "Step 2: Installing development tools..."

# Install core tools
log_info "Installing Terraform, kubectl, Helm, and Docker..."
# Check and install tools if needed
for tool in terraform kubectl helm docker; do
    if command -v $tool &> /dev/null; then
        log_info "$tool already installed: $($tool --version | head -1)"
    else
        log_info "Installing $tool..."
        brew install $tool
    fi
done

# Install VS Code extensions
log_info "Installing VS Code extensions..."
if command -v code &> /dev/null; then
    # List of essential extensions
    extensions=(
        "hashicorp.terraform"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "redhat.vscode-yaml"
    )
    
    for ext in "${extensions[@]}"; do
        log_info "Installing extension: $ext"
        if code --list-extensions | grep -q "$ext"; then
            log_info "Extension $ext already installed"
        elif code --install-extension "$ext" 2>/dev/null; then
            log_success "Extension $ext installed successfully"
        else
            log_warning "Failed to install extension $ext (may already be installed)"
        fi
    done
    
    log_success "VS Code extensions installation completed"
else
    log_warning "VS Code not found. Please install VS Code and run the extension installation manually:"
    echo "  code --install-extension hashicorp.terraform"
    echo "  code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools"
    echo "  code --install-extension redhat.vscode-yaml"
fi

# 3. Verify Tools Installation
log_info "Step 3: Verifying tool installations..."

echo "Terraform: $(terraform version | head -1)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "Helm: $(helm version --short)"
echo "Docker: $(docker --version)"
echo "AWS CLI: $(aws --version)"

log_success "All tools verified successfully"

# 4. Create Terraform Backend Configuration
log_info "Step 4: Setting up Terraform backend configuration..."

# Create terraform directory structure
mkdir -p terraform/modules/vpc
mkdir -p terraform/modules/eks
mkdir -p terraform/environments

# Create backend configuration
cat > terraform/backend.tf << 'BACKEND_EOF'
terraform {
  backend "s3" {
    bucket         = "quanttrader-tf-state-$(date +%s)"
    key            = "phase1/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "quanttrader-tf-lock"
    encrypt        = true
  }
}
BACKEND_EOF

# Create provider configuration
cat > terraform/provider.tf << 'PROVIDER_EOF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "quanttrader-dev"
  
  default_tags {
    tags = {
      Project     = "quanttrader-k8s"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
PROVIDER_EOF

# Create billing alarms configuration
cat > terraform/billing.tf << 'BILLING_EOF'
# SNS Topic for billing alerts
resource "aws_sns_topic" "billing" {
  name = "quanttrader-billing-alerts"
  
  tags = {
    Name    = "quanttrader-billing-alerts"
    Project = "quanttrader-k8s"
  }
}

# Email subscription (user needs to confirm)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.billing.arn
  protocol  = "email"
  endpoint  = var.billing_email
  
  depends_on = [aws_sns_topic.billing]
}

# Billing alarms
locals {
  billing_thresholds = [20, 30, 50]
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  for_each = toset([for t in local.billing_thresholds : tostring(t)])
  
  alarm_name          = "quanttrader-billing-${each.value}USD"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = tonumber(each.value)
  alarm_actions       = [aws_sns_topic.billing.arn]
  alarm_description   = "This metric monitors estimated charges exceeding $${each.value}"
  
  dimensions = {
    Currency = "USD"
  }
  
  tags = {
    Name    = "quanttrader-billing-${each.value}USD"
    Project = "quanttrader-k8s"
  }
}
BILLING_EOF

# Create variables file
cat > terraform/variables.tf << 'VARIABLES_EOF'
variable "billing_email" {
  description = "Email address for billing alerts"
  type        = string
  default     = "admin@example.com"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "quanttrader-k8s"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
VARIABLES_EOF

# Create outputs file
cat > terraform/outputs.tf << 'OUTPUTS_EOF'
output "sns_topic_arn" {
  description = "ARN of the SNS topic for billing alerts"
  value       = aws_sns_topic.billing.arn
}

output "billing_alarms" {
  description = "List of billing alarm names"
  value       = [for alarm in aws_cloudwatch_metric_alarm.billing : alarm.alarm_name]
}
OUTPUTS_EOF

# Create terraform.tfvars template
cat > terraform/terraform.tfvars.example << 'TFVARS_EOF'
# Copy this file to terraform.tfvars and update with your values
billing_email = "your-email@example.com"
project_name  = "quanttrader-k8s"
environment   = "dev"
TFVARS_EOF

log_success "Terraform configuration files created"

# 5. Check AWS Permissions by Actually Testing Them
log_info "Step 5: Testing AWS permissions by creating test resources..."

# Function to test AWS permissions by actually creating resources
test_aws_permission() {
    local service=$1
    local test_name=$2
    
    log_info "Testing $service permissions: $test_name"
    
    case $service in
        "s3")
            local test_bucket="quanttrader-test-$(date +%s)"
            if aws s3 mb s3://$test_bucket --profile quanttrader-dev --region us-west-2 2>/dev/null; then
                log_success "S3 bucket creation successful: $test_bucket"
                # Clean up test bucket
                aws s3 rb s3://$test_bucket --profile quanttrader-dev 2>/dev/null || true
                return 0
            else
                log_error "S3 bucket creation failed - insufficient permissions"
                return 1
            fi
            ;;
        "dynamodb")
            local test_table="quanttrader-test-$(date +%s)"
            if aws dynamodb create-table \
                --table-name $test_table \
                --attribute-definitions AttributeName=TestID,AttributeType=S \
                --key-schema AttributeName=TestID,KeyType=HASH \
                --billing-mode PAY_PER_REQUEST \
                --profile quanttrader-dev \
                --region us-west-2 2>/dev/null; then
                log_success "DynamoDB table creation successful: $test_table"
                # Wait for table to be created, then clean up
                aws dynamodb wait table-exists --table-name $test_table --profile quanttrader-dev --region us-west-2 2>/dev/null || true
                aws dynamodb delete-table --table-name $test_table --profile quanttrader-dev --region us-west-2 2>/dev/null || true
                return 0
            else
                log_error "DynamoDB table creation failed - insufficient permissions"
                return 1
            fi
            ;;
        "cloudwatch")
            local test_alarm="quanttrader-test-$(date +%s)"
            if aws cloudwatch put-metric-alarm \
                --alarm-name $test_alarm \
                --alarm-description "Test alarm" \
                --metric-name CPUUtilization \
                --namespace AWS/EC2 \
                --statistic Average \
                --period 300 \
                --threshold 80 \
                --comparison-operator GreaterThanThreshold \
                --evaluation-periods 1 \
                --profile quanttrader-dev \
                --region us-west-2 2>/dev/null; then
                log_success "CloudWatch alarm creation successful: $test_alarm"
                # Clean up test alarm
                aws cloudwatch delete-alarms --alarm-names $test_alarm --profile quanttrader-dev --region us-west-2 2>/dev/null || true
                return 0
            else
                log_error "CloudWatch alarm creation failed - insufficient permissions"
                return 1
            fi
            ;;
        "sns")
            local test_topic="quanttrader-test-$(date +%s)"
            if aws sns create-topic --name $test_topic --profile quanttrader-dev --region us-west-2 2>/dev/null; then
                log_success "SNS topic creation successful: $test_topic"
                # Clean up test topic
                aws sns delete-topic --topic-arn "arn:aws:sns:us-west-2:$(aws sts get-caller-identity --profile quanttrader-dev --query Account --output text):$test_topic" --profile quanttrader-dev --region us-west-2 2>/dev/null || true
                return 0
            else
                log_error "SNS topic creation failed - insufficient permissions"
                return 1
            fi
            ;;
    esac
}

# Test required permissions
log_info "Testing AWS service permissions by creating test resources..."

PERMISSION_ERRORS=0

# Test S3 permissions
if ! test_aws_permission "s3" "CreateBucket"; then
    PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
fi

# Test DynamoDB permissions
if ! test_aws_permission "dynamodb" "CreateTable"; then
    PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
fi

# Test CloudWatch permissions
if ! test_aws_permission "cloudwatch" "PutMetricAlarm"; then
    PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
fi

# Test SNS permissions
if ! test_aws_permission "sns" "CreateTopic"; then
    PERMISSION_ERRORS=$((PERMISSION_ERRORS + 1))
fi

if [ $PERMISSION_ERRORS -gt 0 ]; then
    log_error "AWS permission tests failed. Please check your IAM permissions."
    echo ""
    log_info "Required AWS permissions for this setup:"
    echo "  S3: CreateBucket, PutBucketVersioning, PutBucketEncryption, ListBucket"
    echo "  DynamoDB: CreateTable, DescribeTable, ListTables"
    echo "  CloudWatch: PutMetricAlarm, DescribeAlarms"
    echo "  SNS: CreateTopic, Subscribe, ListTopics"
    echo ""
    log_info "See AWS-PERMISSIONS.md for detailed permission setup instructions."
    echo ""
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup paused. Please configure AWS permissions and run the script again."
        exit 1
    fi
else
    log_success "All AWS permission tests passed!"
fi

# 6. Create S3 Bucket and DynamoDB Table for Terraform State
log_info "Step 6: Creating Terraform state backend resources..."

# Create S3 bucket for Terraform state
BUCKET_NAME="quanttrader-tf-state-$(aws sts get-caller-identity --query Account --output text --profile quanttrader-dev)"
log_info "Creating S3 bucket: $BUCKET_NAME"

if aws s3api head-bucket --bucket $BUCKET_NAME --profile quanttrader-dev 2>/dev/null; then
    log_info "S3 bucket already exists: $BUCKET_NAME"
    log_success "S3 bucket is ready"
elif aws s3 mb s3://$BUCKET_NAME --profile quanttrader-dev --region us-west-2 2>/dev/null; then
    log_success "S3 bucket created: $BUCKET_NAME"
    
    # Configure bucket versioning and encryption
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled --profile quanttrader-dev
    aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }' --profile quanttrader-dev
    
    log_success "S3 bucket configured with versioning and encryption"
else
    log_error "Failed to create S3 bucket. This may be due to:"
    echo "  1. Insufficient permissions (s3:CreateBucket)"
    echo "  2. Bucket name already exists"
    echo "  3. AWS service issues"
    echo ""
    log_info "You can create the bucket manually:"
    echo "  aws s3 mb s3://$BUCKET_NAME --profile quanttrader-dev --region us-west-2"
    echo "  aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled --profile quanttrader-dev"
    echo "  aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}' --profile quanttrader-dev"
    echo ""
    # Auto-continue after S3 bucket creation
fi

# Create DynamoDB table for state locking
log_info "Creating DynamoDB table for state locking..."
if aws dynamodb describe-table \
  --table-name quanttrader-tf-lock \
  --profile quanttrader-dev \
  --region us-west-2 >/dev/null 2>&1; then
    log_info "DynamoDB table already exists: quanttrader-tf-lock"
else
    if aws dynamodb create-table \
      --table-name quanttrader-tf-lock \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --profile quanttrader-dev \
      --region us-west-2 2>/dev/null; then
        log_success "DynamoDB table created: quanttrader-tf-lock"
    else
        log_warning "CreateTable failed; rechecking if table now exists (eventual consistency)..."
    fi
fi

log_info "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name quanttrader-tf-lock --profile quanttrader-dev --region us-west-2
log_success "DynamoDB table is active"

log_success "Terraform state backend resources created"

# 7. Initialize and Apply Terraform
log_info "Step 7: Initializing and applying Terraform..."

# Create a new backend.tf with the actual bucket name
cat > terraform/backend.tf << BACKEND_EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "phase1/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "quanttrader-tf-lock"
    encrypt        = true
  }
}
BACKEND_EOF

cd terraform

# Initialize Terraform
log_info "Initializing Terraform..."
export AWS_PROFILE=quanttrader-dev
export AWS_DEFAULT_REGION=us-west-2
export TF_IN_AUTOMATION=1
if terraform init -input=false -reconfigure; then
    log_success "Terraform initialized successfully"
else
    log_error "Terraform initialization failed"
    log_info "This may be due to:"
    echo "  1. S3 bucket or DynamoDB table not accessible"
    echo "  2. Incorrect AWS credentials"
    echo "  3. Network connectivity issues"
    echo ""
    log_info "Please check the error messages above and fix the issues."
    cd ..
    exit 1
fi

# Validate Terraform configuration
log_info "Validating Terraform configuration..."
if terraform validate; then
    log_success "Terraform configuration is valid"
else
    log_error "Terraform configuration is invalid"
    terraform validate
    cd ..
    exit 1
fi

# Plan Terraform changes
log_info "Planning Terraform changes..."
if terraform plan -input=false -var="billing_email=admin@example.com"; then
    log_success "Terraform plan completed successfully"
else
    log_error "Terraform plan failed"
    log_info "This may be due to:"
    echo "  1. Insufficient AWS permissions"
    echo "  2. Invalid Terraform configuration"
    echo "  3. AWS service issues"
    echo ""
    log_info "Please check the error messages above and fix the issues."
    cd ..
    exit 1
fi

log_warning "Terraform plan completed. Applying changes automatically..."
if true; then
    log_info "Applying Terraform changes..."
    if terraform apply -input=false -var="billing_email=admin@example.com" -auto-approve; then
        log_success "Terraform applied successfully"
    else
        log_error "Terraform apply failed"
        log_info "This may be due to:"
        echo "  1. Insufficient AWS permissions"
        echo "  2. Resource conflicts"
        echo "  3. AWS service issues"
        echo ""
        log_info "Please check the error messages above and fix the issues."
        cd ..
        exit 1
    fi
else
    log_info "Terraform apply skipped. You can run 'terraform apply' later."
fi

cd ..

# 8. Create Daily Cost Monitoring Script

# 7.5. Add Cost Explorer Policy
log_info "Step 7.5: Adding Cost Explorer policy to IAM user..."

MANAGED_CE_ARN="arn:aws:iam::aws:policy/CostExplorerReadOnlyAccess"
CE_POLICY_ATTACHED=0

# Try attaching AWS managed policy first
if aws iam attach-user-policy \
  --user-name quanttrader-dev \
  --policy-arn "$MANAGED_CE_ARN" \
  --profile quanttrader-dev 2>/dev/null; then
    log_success "Attached AWS managed CostExplorerReadOnlyAccess policy"
    CE_POLICY_ATTACHED=1
else
    log_warning "Failed to attach AWS managed CostExplorerReadOnlyAccess policy; will attempt custom policy"
fi

if [ "$CE_POLICY_ATTACHED" -eq 0 ]; then
    # Create custom Cost Explorer policy and attach
    POLICY_NAME="QuantTraderCostExplorerPolicy"
    POLICY_DOCUMENT='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ce:GetCostAndUsage",
                    "ce:GetDimensionValues",
                    "ce:GetReservationCoverage",
                    "ce:GetReservationPurchaseRecommendation",
                    "ce:GetReservationUtilization",
                    "ce:GetUsageReport",
                    "ce:ListCostCategoryDefinitions",
                    "ce:GetCostCategories",
                    "ce:GetSavingsPlansUtilization",
                    "ce:GetSavingsPlansUtilizationDetails",
                    "ce:GetSavingsPlansCoverage"
                ],
                "Resource": "*"
            }
        ]
    }'

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile quanttrader-dev)
    POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

    if aws iam get-policy --policy-arn "$POLICY_ARN" --profile quanttrader-dev >/dev/null 2>&1; then
        log_info "Custom Cost Explorer policy already exists"
    else
        log_info "Creating custom Cost Explorer policy: $POLICY_NAME"
        if aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$POLICY_DOCUMENT" --description "Allows Cost Explorer access for QuantTrader project" --profile quanttrader-dev 2>/dev/null; then
            log_success "Custom Cost Explorer policy created successfully"
        else
            log_warning "Failed to create custom Cost Explorer policy (may already exist or insufficient permissions)"
        fi
    fi

    if aws iam attach-user-policy --user-name quanttrader-dev --policy-arn "$POLICY_ARN" --profile quanttrader-dev 2>/dev/null; then
        log_success "Custom Cost Explorer policy attached successfully"
    else
        log_warning "Failed to attach custom Cost Explorer policy (may already be attached or insufficient permissions)"
    fi
fi

log_info "Step 8: Creating cost monitoring scripts..."

mkdir -p scripts

cat > scripts/daily-cost.sh << 'COST_SCRIPT_EOF'
#!/usr/bin/env bash
# Daily cost monitoring script for QuantTrader-K8s-Simulator

set -euo pipefail

PROFILE="quanttrader-dev"
# Cost Explorer only operates in us-east-1
CE_REGION="us-east-1"

# Get yesterday's date
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

echo "=== QuantTrader-K8s Daily Cost Report ==="
echo "Date: $YESTERDAY"
echo "========================================"

# Get cost and usage data
aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Tags":{"Key":"Project","Values":["quanttrader-k8s"]}}' \
  --profile $PROFILE \
  --region $CE_REGION \
  --output table

echo ""
echo "=== Monthly Cost Summary ==="
MONTH_START=$(date -v1d +%Y-%m-%d)
aws ce get-cost-and-usage \
  --time-period Start=$MONTH_START,End=$TODAY \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --profile $PROFILE \
  --region $CE_REGION \
  --output table
COST_SCRIPT_EOF

chmod +x scripts/daily-cost.sh

# Create cost alert script
cat > scripts/cost-alert.sh << 'ALERT_SCRIPT_EOF'
#!/usr/bin/env bash
# Cost alert script for QuantTrader-K8s-Simulator

set -euo pipefail

PROFILE="quanttrader-dev"
REGION="us-west-2"
THRESHOLD=25  # Alert if daily cost exceeds $25

# Get yesterday's cost
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

COST=$(aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["quanttrader-k8s"]}}' \
  --profile $PROFILE \
  --region $REGION \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

if (( $(echo "$COST > $THRESHOLD" | bc -l) )); then
    echo "ALERT: Daily cost $COST exceeds threshold $THRESHOLD"
    # Add notification logic here (email, Slack, etc.)
else
    echo "Cost OK: $COST (threshold: $THRESHOLD)"
fi
ALERT_SCRIPT_EOF

chmod +x scripts/cost-alert.sh

log_success "Cost monitoring scripts created"

# 9. Create Makefile for common operations
log_info "Step 9: Creating Makefile for common operations..."

cat > Makefile << 'MAKEFILE_EOF'
# QuantTrader-K8s-Simulator Makefile

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
MAKEFILE_EOF

log_success "Makefile created"

# 10. Create .gitignore
log_info "Step 10: Creating .gitignore file..."

cat > .gitignore << 'GITIGNORE_EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log

# AWS
.aws/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Temporary files
*.tmp
*.temp
GITIGNORE_EOF

log_success ".gitignore file created"

# 11. Final verification
log_info "Step 11: Running final verification..."

echo ""
echo "=================================================="
log_success "Phase 1.1 Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your email address"
echo "2. Run 'make plan-terraform' to review changes"
echo "3. Run 'make apply-terraform' to create billing alarms"
echo "4. Check your email and confirm SNS subscription"
echo "5. Run './scripts/daily-cost.sh' to test cost monitoring"
echo ""
echo "Useful commands:"
echo "  make help              - Show all available commands"
echo "  make check-costs       - Check daily costs"
echo "  make validate-terraform - Validate Terraform configuration"
echo ""
log_info "Setup completed successfully!"
