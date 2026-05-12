data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 事前に作成済みのSecrets ManagerのARNを取得
data "aws_secretsmanager_secret" "commons" {
  name = "${var.project}_commons"
}

# 1. PythonスクリプトをZIP化
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src/cost_reporter.zip"
}

# 2. Lambda用 IAMロールの作成
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project
  }
}

# CloudWatch Logs出力権限のアタッチ
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# カスタム権限（CE, SecretsManager, IAM）のアタッチ
resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CostReport"
        Effect   = "Allow"
        Action   = ["ce:GetCostAndUsage"]
        Resource = "*"
      },
      {
        Sid      = "GetSecretValue"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [data.aws_secretsmanager_secret.commons.arn]
      },
      {
        Sid      = "ListAccountAliases"
        Effect   = "Allow"
        Action   = ["iam:ListAccountAliases"]
        Resource = "*"
      }
    ]
  })
}

# 3. Lambda関数の作成
resource "aws_lambda_function" "reporter" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "cost_reporter.lambda_handler"
  runtime          = "python3.14"
  timeout          = 20
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  lifecycle {
    ignore_changes = [
      # filename,
      # source_code_hash,
      # environment
    ]
  }

  tags = {
    Project = var.project
  }
}

# 4. EventBridge Scheduler用 IAMロールの作成
resource "aws_iam_role" "scheduler" {
  name = "${var.function_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project
  }
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  name = "${var.function_name}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.reporter.arn
      }
    ]
  })
}

# 5. EventBridge Schedulerの作成
resource "aws_scheduler_schedule" "reporter" {
  name                         = "${var.function_name}-schedule"
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.reporter.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}
