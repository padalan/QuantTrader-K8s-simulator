output "sns_topic_arn" {
  description = "ARN of the SNS topic for billing alerts"
  value       = length(module.billing) > 0 ? module.billing[0].sns_topic_arn : null
}

output "billing_alarms" {
  description = "List of billing alarm names"
  value       = length(module.billing) > 0 ? module.billing[0].billing_alarm_names : []
}

output "deployment_mode" {
  description = "Current deployment mode"
  value       = var.deployment_mode
}
