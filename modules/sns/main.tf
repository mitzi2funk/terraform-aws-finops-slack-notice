resource "aws_sns_topic" "main" {
  name = var.topic_name

  tags = {
    Project = var.project
  }
}

# SNS Topic Policy: 各種FinOpsサービスからのPublishを許可
resource "aws_sns_topic_policy" "main" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    resources = [aws_sns_topic.main.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Budgets用ポリシー
  statement {
    sid    = "AllowBudgetsToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.main.arn]
  }

  # Cost Anomaly Detection用ポリシー
  statement {
    sid    = "AllowAnomalyDetectionToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.main.arn]
  }
}

data "aws_caller_identity" "current" {}
