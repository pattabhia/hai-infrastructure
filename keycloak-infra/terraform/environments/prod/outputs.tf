output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = module.aks.kube_config
  sensitive   = true
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "public_ip_address" {
  description = "Public IP address for load balancer"
  value       = module.networking.public_ip_address
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitoring.workspace_name
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = <<-EOT
  
  ========================================
  Infrastructure Deployed Successfully!
  ========================================
  
  1. Get AKS credentials:
     az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}
  
  2. Verify cluster access:
     kubectl get nodes
  
  3. Deploy Keycloak stack:
     cd ../../../kubernetes
     kubectl apply -k manifests/base
  
  4. Or use Helm:
     helm install keycloak ./helm/keycloak -f ./helm/keycloak/values-dev.yaml
  
  5. Access services:
     kubectl get svc -n keycloak
  
  ========================================
  EOT
}

