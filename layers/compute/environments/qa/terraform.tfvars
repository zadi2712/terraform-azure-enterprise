#=============================================================================
# QA Environment - Compute Layer Configuration
#=============================================================================

# Environment Settings
environment = "qa"
location    = "eastus"

# Project and Tagging
project_name           = "myapp"
cost_center            = "engineering"
owner_team             = "platform-team"
criticality            = "medium"
data_classification    = "internal"

# Additional custom tags
additional_tags = {
  Terraform  = "true"
  Repository = "terraform-azure-enterprise"
}

# Remote State Configuration
state_storage_account_name = "<STORAGE_ACCOUNT_NAME>"
state_resource_group_name  = "rg-terraform-state"

# Availability Zones
availability_zones = ["1", "2", "3"]

#=============================================================================
# AKS Configuration
#=============================================================================

enable_aks             = true
aks_kubernetes_version = "1.28"
aks_dns_service_ip     = "172.16.0.10"
aks_service_cidr       = "172.16.0.0/16"

# AKS Admin Groups (Azure AD Object IDs)
aks_admin_group_object_ids = []  # Add your Azure AD group IDs

# Additional Node Pools
aks_additional_node_pools = {}

# Maintenance Window
aks_maintenance_window = {
  day   = "Sunday"
  hours = [2, 3, 4]
}

#=============================================================================
# App Service Configuration
#=============================================================================

enable_app_service = false

app_service_plan_sku = {
  tier = "Standard"
  size = "S1"
}

#=============================================================================
# VMSS Configuration
#=============================================================================

enable_vmss          = false
vmss_sku             = "Standard_D2s_v3"
vmss_instance_count  = 2
vmss_admin_username  = "azureuser"

#=============================================================================
# Azure Functions Configuration
#=============================================================================

enable_function_app         = false
function_app_runtime        = "node"
function_app_runtime_version = "18"
