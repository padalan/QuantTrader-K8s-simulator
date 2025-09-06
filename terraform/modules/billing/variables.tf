variable "monthly_budget" {
  description = "Monthly AWS budget in USD"
  type        = number
}

variable "billing_email" {
  description = "Email address for billing alerts"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
} 