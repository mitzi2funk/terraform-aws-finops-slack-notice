locals {
  environment = terraform.workspace
  # FinOpsリソースを管理する代表Workspaceのリスト
  finops_manager_workspaces = var.target_workspaces
  is_finops_manager         = contains(local.finops_manager_workspaces, local.environment)
}

module "sns" {
  source     = "./modules/sns"
  count      = local.is_finops_manager ? 1 : 0
  topic_name = var.sns_topic_name
  project    = var.project
}

module "chatbot" {
  source             = "./modules/chatbot"
  count              = local.is_finops_manager ? 1 : 0
  chatbot_name       = var.chatbot_name
  slack_channel_id   = var.slack_channel_id
  slack_workspace_id = var.slack_workspace_id # 事前に連携済みのIDを変数で渡す
  sns_topic_arn      = module.sns[0].sns_topic_arn
  project            = var.project
}

module "budgets" {
  source        = "./modules/budgets"
  count         = local.is_finops_manager ? 1 : 0
  budget_name   = var.budget_name
  budget_amount = var.budget_amount
  sns_topic_arn = module.sns[0].sns_topic_arn
  project       = var.project
}

module "anomaly_detection" {
  source            = "./modules/anomaly_detection"
  count             = local.is_finops_manager ? 1 : 0
  monitor_name      = var.monitor_name
  subscription_name = "${var.monitor_name}_${local.environment}"
  threshold_amount  = "10"
  sns_topic_arn     = module.sns[0].sns_topic_arn
  project           = var.project
}

module "bill" {
  source        = "./modules/bill"
  count         = local.is_finops_manager ? 1 : 0
  function_name = "${var.project}-cost-reporter-${local.environment}"
  project       = var.project
}

# IAM Account Alias の設定
resource "aws_iam_account_alias" "main" {
  count         = local.is_finops_manager ? 1 : 0
  account_alias = "${var.project}-${local.environment}"
}
