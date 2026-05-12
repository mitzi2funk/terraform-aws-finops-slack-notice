# Anomaly Monitor (AWS services タイプのモニター)
resource "aws_ce_anomaly_monitor" "main" {
  name              = var.monitor_name
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = {
    Project = var.project
  }
}

# Anomaly Subscription (アラートサブスクリプション)
resource "aws_ce_anomaly_subscription" "main" {
  name             = var.subscription_name
  frequency        = "IMMEDIATE" # Individual alerts に該当
  monitor_arn_list = [aws_ce_anomaly_monitor.main.arn]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [var.threshold_amount]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
  }

  tags = {
    Project = var.project
  }
}
