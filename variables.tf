#----------------------------------
# global variables
#----------------------------------
variable "target_workspaces" {
  type        = list(string)
  description = "FinOpsリソースを作成する対象のWorkspaceリスト"
  default     = ["default", "stg", "prd"]
}

variable "project" {
  type    = string
  default = "finops"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "budget_name" {
  type        = string
  description = "Name of the AWS Budget"
  default     = "finops_monthly_budget"
}

variable "budget_amount" {
  type = string
}

variable "monitor_name" {
  type        = string
  description = "Name of Cost Anomaly Detection Monitor"
  default     = "finops_notify_cost"
}

variable "sns_topic_name" {
  type        = string
  description = "SNS Topic name for FinOps notifications"
  default     = "finops_notify_cost"
}

variable "chatbot_name" {
  type    = string
  default = "finops_notify_cost"
}

variable "slack_channel_id" {
  type        = string
  description = "連携するSlackのチャンネルID (例: C0123456789)"
  # default     = "C0123456789" #ご自身の環境の値を設定ください
}

variable "slack_workspace_id" {
  type        = string
  description = "連携するSlackワークスペースID (例: T0123456789)"
  #default     = "T0123456789" #ご自身の環境の値を設定ください
}
