variable "project" {
  type = string
}
variable "subscription_name" {
  type = string
}
variable "threshold_amount" {
  type    = string
  default = "10"
}
variable "sns_topic_arn" {
  type = string
}
variable "monitor_name" {
  type        = string
  description = "Name of Cost Anomaly Detection Monitor"
}
