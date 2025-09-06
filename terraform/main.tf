locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Conditional resource creation based on deployment mode
locals {
  create_aws_resources = var.deployment_mode != "local"
}

# Only create AWS resources when not in local mode
module "billing" {
  count  = local.create_aws_resources ? 1 : 0
  source = "./modules/billing"

  monthly_budget = var.monthly_budget
  billing_email  = var.billing_email
  common_tags    = local.common_tags
}
