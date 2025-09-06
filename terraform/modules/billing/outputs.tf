output "sns_topic_arn" {
  description = "ARN of the SNS topic for billing alerts"
  value       = aws_sns_topic.billing.arn
}

output "billing_alarm_names" {
  description = "List of billing alarm names"
  value       = [for alarm in aws_cloudwatch_metric_alarm.billing : alarm.alarm_name]
} 