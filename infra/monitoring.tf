resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "url-shortener-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "5XX errors exceeding threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = module.alb.arn_suffix
  }
}

resource "aws_sns_topic" "alerts" {
  name = "url-shortener-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "stefanmirandaeng@gmail.com"
}