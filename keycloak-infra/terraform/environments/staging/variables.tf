variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "haiintel-keycloak"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-haiintel-keycloak-dev"
}

# Networking
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for AKS subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "data_subnet_address_prefixes" {
  description = "Address prefixes for data subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "appgw_subnet_address_prefixes" {
  description = "Address prefixes for application gateway subnet"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

# AKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for nodes (cost-optimized for dev)"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 3
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admins"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "HAI Intel Keycloak"
    ManagedBy = "Terraform"
  }
}

