/**
 * Compute Layer - Root Configuration
 * 
 * This layer manages compute resources including:
 * - Azure Kubernetes Service (AKS)
 * - Virtual Machine Scale Sets (VMSS)
 * - Azure App Service
 * - Azure Functions
 * - Container Instances
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration provided via backend.conf file
    # terraform init -backend-config=environments/<env>/backend.conf
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine_scale_set {
      roll_instances_when_required = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Remote state data - networking layer
data "terraform_remote_state" "networking" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "networking-${var.environment}.tfstate"
    resource_group_name  = var.state_resource_group_name
  }
}

# Remote state data - security layer
data "terraform_remote_state" "security" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "security-${var.environment}.tfstate"
    resource_group_name  = var.state_resource_group_name
  }
}

#=============================================================================
# Resource Group
#=============================================================================

module "compute_rg" {
  source = "../../modules/resource-group"

  name     = "rg-${local.naming_prefix}-compute-${var.location}"
  location = var.location
  tags     = local.common_tags

  lock_level = var.environment == "prod" ? "CanNotDelete" : null
}

#=============================================================================
# AKS Cluster
#=============================================================================

module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "../../modules/compute/aks"

  cluster_name        = "aks-${local.naming_prefix}"
  location            = var.location
  resource_group_name = module.compute_rg.name
  dns_prefix          = "${local.naming_prefix}-aks"
  kubernetes_version  = var.aks_kubernetes_version
  sku_tier            = local.aks_config.sku_tier

  # Default node pool configuration
  default_node_pool = {
    name                = "system"
    vm_size             = local.aks_config.system_node_pool_vm_size
    node_count          = local.aks_config.system_node_pool_count
    enable_auto_scaling = true
    min_count           = local.aks_config.system_node_pool_min_count
    max_count           = local.aks_config.system_node_pool_max_count
    max_pods            = 110
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    subnet_id           = data.terraform_remote_state.networking.outputs.subnet_aks_system_id
    availability_zones  = var.availability_zones
    max_surge           = "33%"
  }

  # Additional node pools
  additional_node_pools = var.aks_additional_node_pools

  # Network configuration
  network_plugin = "azure"
  network_policy = "azure"
  dns_service_ip = var.aks_dns_service_ip
  service_cidr   = var.aks_service_cidr
  outbound_type  = "loadBalancer"

  # Azure AD integration
  admin_group_object_ids = var.aks_admin_group_object_ids
  azure_rbac_enabled     = true

  # Monitoring
  log_analytics_workspace_id = try(data.terraform_remote_state.security.outputs.log_analytics_workspace_id, null)

  # Security features
  private_cluster_enabled   = local.aks_config.private_cluster_enabled
  azure_policy_enabled      = true
  enable_host_encryption    = true
  enable_secret_rotation    = true
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # Maintenance window
  maintenance_window = var.aks_maintenance_window

  identity_type = "SystemAssigned"
  identity_ids  = []

  tags = local.common_tags

  depends_on = [module.compute_rg]
}
