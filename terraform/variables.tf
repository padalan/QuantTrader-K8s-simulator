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

variable "monthly_budget" {
  description = "Monthly AWS budget in USD"
  type        = number
  default     = 50

  validation {
    condition     = var.monthly_budget > 0 && var.monthly_budget <= 1000
    error_message = "Monthly budget must be between 1 and 1000 USD."
  }
}

variable "deployment_mode" {
  description = "Deployment mode: local, hobby, or production"
  type        = string
  default     = "local"

  validation {
    condition     = contains(["local", "hobby", "production"], var.deployment_mode)
    error_message = "Deployment mode must be local, hobby, or production."
  }
}
