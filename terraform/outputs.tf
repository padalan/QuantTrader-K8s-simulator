output "sns_topic_arn" {
  description = "ARN of the SNS topic for billing alerts"
  value       = module.billing.sns_topic_arn
}

output "billing_alarms" {
  description = "List of billing alarm names"
  value       = module.billing.billing_alarm_names
}
