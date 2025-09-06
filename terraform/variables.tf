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
