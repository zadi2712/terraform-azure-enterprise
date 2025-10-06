/**
 * Log Analytics Workspace Module
 * 
 * Creates Log Analytics Workspace with:
 * - Data retention configuration
 * - Diagnostic settings
 * - Solutions (optional)
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.tags
}

# Solutions
resource "azurerm_log_analytics_solution" "this" {
  for_each = var.solutions

  solution_name         = each.key
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = var.tags
}
