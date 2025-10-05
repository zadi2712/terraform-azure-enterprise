/**
 * Network Security Group Module
 * 
 * Creates NSG with custom security rules
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

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.security_rules : rule.name => rule }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = try(each.value.source_port_range, "*")
  destination_port_range      = try(each.value.destination_port_range, null)
  destination_port_ranges     = try(each.value.destination_port_ranges, null)
  source_address_prefix       = try(each.value.source_address_prefix, null)
  source_address_prefixes     = try(each.value.source_address_prefixes, null)
  destination_address_prefix  = try(each.value.destination_address_prefix, null)
  destination_address_prefixes = try(each.value.destination_address_prefixes, null)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
}

# NSG to Subnet Association
resource "azurerm_subnet_network_security_group_association" "this" {
  count = var.subnet_id != null ? 1 : 0

  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
