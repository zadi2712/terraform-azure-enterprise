#=============================================================================
# Environment Variables
#=============================================================================

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, qa, uat, or prod."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

#=============================================================================
# Project and Tagging Variables
#=============================================================================

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
}

variable "owner_team" {
  description = "Team responsible for resources"
  type        = string
}

variable "criticality" {
  description = "Criticality level"
  type        = string
  default     = "medium"
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "internal"
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

#=============================================================================
# Remote State Variables
#=============================================================================

variable "state_storage_account_name" {
  description = "Storage account name for remote state"
  type        = string
}

variable "state_resource_group_name" {
  description = "Resource group name for state storage"
  type        = string
  default     = "rg-terraform-state"
}

variable "enable_security_integration" {
  description = "Enable integration with security layer (for Key Vault, Log Analytics)"
  type        = bool
  default     = true
}

#=============================================================================
# General Compute Variables
#=============================================================================

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = ["1", "2", "3"]
}

#=============================================================================
# AKS Variables
#=============================================================================

variable "enable_aks" {
  description = "Enable AKS cluster deployment"
  type        = bool
  default     = true
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

variable "aks_dns_service_ip" {
  description = "DNS service IP for AKS"
  type        = string
  default     = "172.16.0.10"
}

variable "aks_service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "172.16.0.0/16"
}

variable "aks_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster admin"
  type        = list(string)
  default     = []
}

variable "aks_additional_node_pools" {
  description = "Additional node pools for AKS"
  type = map(object({
    name                = string
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    os_disk_size_gb     = number
    os_disk_type        = string
    subnet_id           = string
    availability_zones  = list(string)
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string
    priority            = string
    spot_max_price      = number
    max_surge           = string
  }))
  default = {}
}

variable "aks_maintenance_window" {
  description = "Maintenance window for AKS"
  type = object({
    day   = string
    hours = list(number)
  })
  default = {
    day   = "Saturday"
    hours = [2, 3, 4]
  }
}

#=============================================================================
# App Service Variables
#=============================================================================

variable "enable_app_service" {
  description = "Enable App Service deployment"
  type        = bool
  default     = false
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type = object({
    tier = string
    size = string
  })
  default = {
    tier = "Standard"
    size = "S1"
  }
}

#=============================================================================
# Virtual Machine Scale Set Variables
#=============================================================================

variable "enable_vmss" {
  description = "Enable VMSS deployment"
  type        = bool
  default     = false
}

variable "vmss_sku" {
  description = "VM SKU for scale set"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vmss_instance_count" {
  description = "Number of VM instances"
  type        = number
  default     = 2
}

variable "vmss_admin_username" {
  description = "Admin username for VMSS"
  type        = string
  default     = "azureuser"
}

#=============================================================================
# Azure Functions Variables
#=============================================================================

variable "enable_function_app" {
  description = "Enable Azure Functions deployment"
  type        = bool
  default     = false
}

variable "function_app_runtime" {
  description = "Runtime for Azure Functions"
  type        = string
  default     = "node"
}

variable "function_app_runtime_version" {
  description = "Runtime version"
  type        = string
  default     = "18"
}
