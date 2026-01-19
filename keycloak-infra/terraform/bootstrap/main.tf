# Bootstrap Terraform Configuration
# This creates the foundational resources needed for Terraform state management
# Run this ONCE before deploying the main infrastructure

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# Data sources
data "azurerm_client_config" "current" {}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group for Terraform state
resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_resource_group_name
  location = var.location
  
  tags = merge(
    var.common_tags,
    {
      Purpose = "Terraform State Storage"
    }
  )
}

# Storage Account for Terraform state
resource "azurerm_storage_account" "tfstate" {
  name                     = "${var.tfstate_storage_account_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
  }
  
  tags = merge(
    var.common_tags,
    {
      Purpose = "Terraform State Storage"
    }
  )
}

# Container for Terraform state
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                       = "${var.key_vault_prefix}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.tfstate.location
  resource_group_name        = azurerm_resource_group.tfstate.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
    
    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Purge"
    ]
    
    key_permissions = [
      "Get", "List", "Create", "Delete", "Purge"
    ]
  }
  
  tags = merge(
    var.common_tags,
    {
      Purpose = "Secrets Management"
    }
  )
}

# Service Principal for GitHub Actions (optional - can be created manually)
resource "azuread_application" "github_actions" {
  count        = var.create_service_principal ? 1 : 0
  display_name = "${var.project_name}-github-actions"
}

resource "azuread_service_principal" "github_actions" {
  count          = var.create_service_principal ? 1 : 0
  application_id = azuread_application.github_actions[0].application_id
}

resource "azuread_service_principal_password" "github_actions" {
  count                = var.create_service_principal ? 1 : 0
  service_principal_id = azuread_service_principal.github_actions[0].object_id
}

# Role assignment for Service Principal
resource "azurerm_role_assignment" "github_actions" {
  count                = var.create_service_principal ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions[0].object_id
}

# Store Service Principal credentials in Key Vault
resource "azurerm_key_vault_secret" "sp_client_id" {
  count        = var.create_service_principal ? 1 : 0
  name         = "github-actions-client-id"
  value        = azuread_application.github_actions[0].application_id
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "sp_client_secret" {
  count        = var.create_service_principal ? 1 : 0
  name         = "github-actions-client-secret"
  value        = azuread_service_principal_password.github_actions[0].value
  key_vault_id = azurerm_key_vault.main.id
}

