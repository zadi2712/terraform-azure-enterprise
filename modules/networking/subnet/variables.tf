variable "name" {
  description = "Name of the subnet"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "virtual_network_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
}

variable "service_endpoints" {
  description = "List of service endpoints"
  type        = list(string)
  default     = []
}

variable "private_endpoint_network_policies_enabled" {
  description = "Enable or disable network policies for private endpoints"
  type        = bool
  default     = true
}

variable "private_link_service_network_policies_enabled" {
  description = "Enable or disable network policies for private link service"
  type        = bool
  default     = true
}

variable "delegation" {
  description = "Subnet delegation configuration"
  type = object({
    name         = string
    service_name = string
    actions      = list(string)
  })
  default = null
}
