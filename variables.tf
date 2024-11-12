variable "location" {
  description = "The Azure region to deploy in"
  type        = string
  default     = "eastus" # You can change this default value as needed
}

variable "vm_size" {
  description = "The size of the VM instances"
  type        = string
  default     = "Standard_D2d_v5" # You can change this default value as needed
}

variable "enable_telemetry" {
  description = "Enable telemetry for the AKS cluster"
  type        = bool
  default     = true # You can change this default value as needed
}

variable "kubernetes_cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "prod-aks-cluster" # You can change this default value as needed
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.31.0.0/16"]
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "prod-vnet" # You can change this default value as needed
}