# Development Environment Configuration

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  # Backend configuration - update after bootstrap
  backend "azurerm" {
    # These values will be provided via backend config file or command line
    # resource_group_name  = "rg-haiintel-tfstate"
    # storage_account_name = "sthaiinteltfstateXXXXXX"
    # container_name       = "tfstate"
    # key                  = "dev/keycloak.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = local.common_tags
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  workspace_name      = "${var.project_name}-dev-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = var.log_retention_days
  
  tags = local.common_tags
}

# Networking
module "networking" {
  source = "../../modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = "${var.project_name}-dev-vnet"
  vnet_address_space  = var.vnet_address_space
  
  aks_subnet_address_prefixes   = var.aks_subnet_address_prefixes
  data_subnet_address_prefixes  = var.data_subnet_address_prefixes
  appgw_subnet_address_prefixes = var.appgw_subnet_address_prefixes
  
  create_public_ip = true
  
  tags = local.common_tags
}

# AKS Cluster
module "aks" {
  source = "../../modules/aks"
  
  cluster_name        = "${var.project_name}-dev-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-dev"
  
  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  vm_size            = var.vm_size
  
  enable_auto_scaling = var.enable_auto_scaling
  min_node_count      = var.min_node_count
  max_node_count      = var.max_node_count
  
  subnet_id                  = module.networking.aks_subnet_id
  vnet_id                    = module.networking.vnet_id
  log_analytics_workspace_id = module.monitoring.workspace_id
  
  admin_group_object_ids = var.admin_group_object_ids
  
  tags = local.common_tags
  
  depends_on = [module.networking, module.monitoring]
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.aks.cluster_fqdn
  cluster_ca_certificate = base64decode(module.aks.kube_config)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server
      "--client-id",
      data.azurerm_client_config.current.client_id,
      "--tenant-id",
      data.azurerm_client_config.current.tenant_id,
      "--login",
      "azurecli"
    ]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_fqdn
    cluster_ca_certificate = base64decode(module.aks.kube_config)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--environment",
        "AzurePublicCloud",
        "--server-id",
        "6dae42f8-4368-4678-94ff-3960e28e3630",
        "--client-id",
        data.azurerm_client_config.current.client_id,
        "--tenant-id",
        data.azurerm_client_config.current.tenant_id,
        "--login",
        "azurecli"
      ]
    }
  }
}

# Local variables
locals {
  common_tags = merge(
    var.common_tags,
    {
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  )
}

