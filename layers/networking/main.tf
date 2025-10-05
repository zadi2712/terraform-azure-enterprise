/**
 * Networking Layer - Root Module
 * 
 * This is a ROOT MODULE that orchestrates networking infrastructure by calling
 * reusable modules from the /modules directory.
 * 
 * NO RESOURCES ARE CREATED DIRECTLY HERE - only module calls.
 * 
 * Creates:
 * - Virtual Networks
 * - Subnets with service endpoints and delegation
 * - Network Security Groups with custom rules
 * - Route tables
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
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

#=============================================================================
# RESOURCE GROUP MODULE
#=============================================================================

module "networking_rg" {
  source = "../../modules/resource-group"

  name     = "rg-${local.naming_prefix}-network-${var.location}"
  location = var.location
  tags     = local.common_tags

  lock_level = var.environment == "prod" ? "CanNotDelete" : null
}

#=============================================================================
# VIRTUAL NETWORK MODULE
#=============================================================================

module "vnet" {
  source = "../../modules/networking/vnet"

  name                = "vnet-${local.naming_prefix}-${var.location}"
  location            = var.location
  resource_group_name = module.networking_rg.name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers

  tags = local.common_tags

  depends_on = [module.networking_rg]
}

#=============================================================================
# SUBNET MODULES
#=============================================================================

# Management Subnet
module "subnet_management" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-management"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_management_cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]

  depends_on = [module.vnet]
}

# Application Gateway Subnet
module "subnet_appgw" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-appgw"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_appgw_cidr]
  service_endpoints    = []

  depends_on = [module.vnet]
}

# AKS System Node Pool Subnet
module "subnet_aks_system" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-aks-system"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_aks_system_cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]

  depends_on = [module.vnet]
}

# AKS User Node Pool Subnet
module "subnet_aks_user" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-aks-user"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_aks_user_cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]

  depends_on = [module.vnet]
}

# Private Endpoints Subnet
module "subnet_private_endpoints" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-privateendpoints"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_private_endpoints_cidr]
  service_endpoints    = []

  private_endpoint_network_policies_enabled = false

  depends_on = [module.vnet]
}

# Database Subnet with Delegation
module "subnet_database" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-database"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_database_cidr]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]

  delegation = {
    name         = "database-delegation"
    service_name = "Microsoft.DBforPostgreSQL/flexibleServers"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
    ]
  }

  depends_on = [module.vnet]
}

# App Service Subnet with Delegation
module "subnet_app_service" {
  source = "../../modules/networking/subnet"

  name                 = "snet-${local.naming_prefix}-appservice"
  resource_group_name  = module.networking_rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [var.subnet_app_service_cidr]
  service_endpoints    = []

  delegation = {
    name         = "appservice-delegation"
    service_name = "Microsoft.Web/serverFarms"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/action",
    ]
  }

  depends_on = [module.vnet]
}

#=============================================================================
# NETWORK SECURITY GROUP MODULES
#=============================================================================

# Management NSG
module "nsg_management" {
  source = "../../modules/networking/nsg"

  name                = "nsg-${local.naming_prefix}-management"
  location            = var.location
  resource_group_name = module.networking_rg.name

  security_rules = [
    {
      name                       = "AllowSSHInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.allowed_management_ips
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowRDPInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = var.allowed_management_ips
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  subnet_id = module.subnet_management.id
  tags      = local.common_tags

  depends_on = [module.subnet_management]
}

# AKS NSG
module "nsg_aks" {
  source = "../../modules/networking/nsg"

  name                = "nsg-${local.naming_prefix}-aks"
  location            = var.location
  resource_group_name = module.networking_rg.name

  security_rules = [
    {
      name                       = "AllowAKSControlPlane"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureCloud"
      destination_address_prefix = "*"
    }
  ]

  tags = local.common_tags

  depends_on = [module.subnet_aks_system, module.subnet_aks_user]
}

# Database NSG
module "nsg_database" {
  source = "../../modules/networking/nsg"

  name                = "nsg-${local.naming_prefix}-database"
  location            = var.location
  resource_group_name = module.networking_rg.name

  security_rules = [
    {
      name                        = "AllowPostgreSQL"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "5432"
      source_address_prefixes     = var.vnet_address_space
      destination_address_prefix  = "*"
    },
    {
      name                        = "AllowMySQL"
      priority                    = 110
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "3306"
      source_address_prefixes     = var.vnet_address_space
      destination_address_prefix  = "*"
    },
    {
      name                        = "AllowSQLServer"
      priority                    = 120
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "1433"
      source_address_prefixes     = var.vnet_address_space
      destination_address_prefix  = "*"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  subnet_id = module.subnet_database.id
  tags      = local.common_tags

  depends_on = [module.subnet_database]
}

#=============================================================================
# ROUTE TABLE MODULE
#=============================================================================

module "route_table_main" {
  source = "../../modules/networking/route-table"

  name                          = "rt-${local.naming_prefix}-main"
  location                      = var.location
  resource_group_name           = module.networking_rg.name
  disable_bgp_route_propagation = local.current_env_config.route_table_disable_bgp

  routes = var.custom_routes

  subnet_ids = [
    module.subnet_aks_system.id,
    module.subnet_aks_user.id
  ]

  tags = local.common_tags

  depends_on = [module.subnet_aks_system, module.subnet_aks_user]
}
