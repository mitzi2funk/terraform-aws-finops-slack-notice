output "monitor_arn" {
  value = aws_ce_anomaly_monitor.main.arn
}
output "subscription_arn" {
  value = aws_ce_anomaly_subscription.main.arn
}
