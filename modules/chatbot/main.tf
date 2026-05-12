resource "aws_iam_role" "chatbot_role" {
  name = "finops_notify_cost_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project
  }
}

# Default policy01: Amazon Q 連携権限
resource "aws_iam_role_policy_attachment" "chatbot_q_access" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonQDeveloperAccess"
}

# Default policy02: CloudWatch Logs用権限（NotificationsOnly相当）
resource "aws_iam_role_policy" "chatbot_notifications_only" {
  name = "AWS-Chatbot-NotificationsOnly-Policy"
  role = aws_iam_role.chatbot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Chatbot設定
resource "aws_chatbot_slack_channel_configuration" "cost_notify" {
  configuration_name = var.chatbot_name
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_team_id      = var.slack_workspace_id
  sns_topic_arns     = [var.sns_topic_arn]
  logging_level      = "ERROR"

  guardrail_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = {
    Project = var.project
  }
}
