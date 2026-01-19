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

variable "tfstate_resource_group_name" {
  description = "Name of the resource group for Terraform state"
  type        = string
  default     = "rg-haiintel-tfstate"
}

variable "tfstate_storage_account_prefix" {
  description = "Prefix for the storage account name (will be appended with random suffix)"
  type        = string
  default     = "sthaiinteltfstate"
  
  validation {
    condition     = length(var.tfstate_storage_account_prefix) <= 18
    error_message = "Storage account prefix must be 18 characters or less to allow for random suffix."
  }
}

variable "key_vault_prefix" {
  description = "Prefix for Key Vault name"
  type        = string
  default     = "kv-haiintel"
}

variable "create_service_principal" {
  description = "Whether to create a service principal for GitHub Actions"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "HAI Intel Keycloak"
    ManagedBy   = "Terraform"
    Environment = "Bootstrap"
  }
}

