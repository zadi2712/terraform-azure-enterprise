variable "name" {
  description = "Log Analytics Workspace name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query"
  type        = bool
  default     = true
}

variable "solutions" {
  description = "Log Analytics solutions"
  type = map(object({
    publisher = string
    product   = string
  }))
  default = {}
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
