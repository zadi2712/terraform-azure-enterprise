output "id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Application Insights name"
  value       = azurerm_application_insights.this.name
}

output "app_id" {
  description = "Application ID"
  value       = azurerm_application_insights.this.app_id
}

output "instrumentation_key" {
  description = "Instrumentation key"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Connection string"
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
