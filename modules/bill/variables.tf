variable "project" {
  type = string
}
variable "function_name" {
  type    = string
  default = "finops-cost-reporter"
}
variable "schedule_expression" {
  type    = string
  default = "cron(0 9 1W * ? *)" # 毎月第1平日のAM9時
}
