variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
  default     = "snet-aks"
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for AKS subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "data_subnet_name" {
  description = "Name of the data subnet"
  type        = string
  default     = "snet-data"
}

variable "data_subnet_address_prefixes" {
  description = "Address prefixes for data subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "appgw_subnet_name" {
  description = "Name of the application gateway subnet"
  type        = string
  default     = "snet-appgw"
}

variable "appgw_subnet_address_prefixes" {
  description = "Address prefixes for application gateway subnet"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "create_public_ip" {
  description = "Whether to create a public IP for load balancer"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

