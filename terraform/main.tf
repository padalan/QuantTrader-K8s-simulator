locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "billing" {
  source = "./modules/billing"

  monthly_budget = var.monthly_budget
  billing_email  = var.billing_email
  common_tags    = local.common_tags
} 