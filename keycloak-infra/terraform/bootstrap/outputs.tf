output "tfstate_resource_group_name" {
  description = "Name of the resource group containing Terraform state"
  value       = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account_name" {
  description = "Name of the storage account for Terraform state"
  value       = azurerm_storage_account.tfstate.name
}

output "tfstate_container_name" {
  description = "Name of the storage container for Terraform state"
  value       = azurerm_storage_container.tfstate.name
}

output "key_vault_name" {
  description = "Name of the Key Vault for secrets"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "service_principal_client_id" {
  description = "Client ID of the GitHub Actions service principal"
  value       = var.create_service_principal ? azuread_application.github_actions[0].application_id : null
  sensitive   = true
}

output "service_principal_client_secret" {
  description = "Client secret of the GitHub Actions service principal"
  value       = var.create_service_principal ? azuread_service_principal_password.github_actions[0].value : null
  sensitive   = true
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}

# Instructions for next steps
output "next_steps" {
  description = "Instructions for configuring GitHub Actions"
  value = <<-EOT
  
  ========================================
  Bootstrap Complete! Next Steps:
  ========================================
  
  1. Configure GitHub Secrets:
     - AZURE_CLIENT_ID: ${var.create_service_principal ? azuread_application.github_actions[0].application_id : "Create manually"}
     - AZURE_CLIENT_SECRET: ${var.create_service_principal ? "(see sensitive output)" : "Create manually"}
     - AZURE_TENANT_ID: ${data.azurerm_client_config.current.tenant_id}
     - AZURE_SUBSCRIPTION_ID: ${data.azurerm_client_config.current.subscription_id}
  
  2. Update backend configuration in environment files:
     - resource_group_name  = "${azurerm_resource_group.tfstate.name}"
     - storage_account_name = "${azurerm_storage_account.tfstate.name}"
     - container_name       = "${azurerm_storage_container.tfstate.name}"
  
  3. Initialize environment Terraform:
     cd ../environments/dev
     terraform init
  
  ========================================
  EOT
}

