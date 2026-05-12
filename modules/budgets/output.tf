output "budget_id" {
  value       = aws_budgets_budget.main.id
  description = "The ID of the created budget"
}
