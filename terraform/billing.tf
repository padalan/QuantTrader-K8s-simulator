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
