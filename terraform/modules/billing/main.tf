terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_sns_topic" "billing" {
  name = "quanttrader-billing-alerts"

  tags = merge(var.common_tags, {
    Name = "quanttrader-billing-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.billing.arn
  protocol  = "email"
  endpoint  = var.billing_email

  depends_on = [aws_sns_topic.billing]
}

locals {
  billing_thresholds = [for pct in [0.4, 0.6, 0.8, 1.0] : var.monthly_budget * pct]
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  for_each = toset([for t in local.billing_thresholds : tostring(t)])

  alarm_name          = "quanttrader-billing-${format("%.0f", tonumber(each.value))}USD"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = tonumber(each.value)
  alarm_actions       = [aws_sns_topic.billing.arn]
  alarm_description   = format("This metric monitors estimated charges exceeding $%s", format("%.0f", tonumber(each.value)))

  dimensions = {
    Currency = "USD"
  }

  tags = merge(var.common_tags, {
    Name = "quanttrader-billing-${format("%.0f", tonumber(each.value))}USD"
  })
} 