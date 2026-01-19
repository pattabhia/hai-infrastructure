output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "data_subnet_id" {
  description = "ID of the data subnet"
  value       = azurerm_subnet.data.id
}

output "data_subnet_name" {
  description = "Name of the data subnet"
  value       = azurerm_subnet.data.name
}

output "appgw_subnet_id" {
  description = "ID of the application gateway subnet"
  value       = azurerm_subnet.appgw.id
}

output "appgw_subnet_name" {
  description = "Name of the application gateway subnet"
  value       = azurerm_subnet.appgw.name
}

output "public_ip_address" {
  description = "Public IP address for load balancer"
  value       = var.create_public_ip ? azurerm_public_ip.lb[0].ip_address : null
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = var.create_public_ip ? azurerm_public_ip.lb[0].id : null
}

