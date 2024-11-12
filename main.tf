terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location # Hardcoded because we have to test in a region with availability zones
  name     = module.naming.resource_group.name_unique
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uami-${var.kubernetes_cluster_name}"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "avm-ptn-aks-production_example_with_availability_zone" {
  source  = "Azure/avm-ptn-aks-production/azurerm//examples/with_availability_zone"
  version = "0.2.0"
  kubernetes_version  = "1.28"
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = var.kubernetes_cluster_name
  resource_group_name = azurerm_resource_group.this.name
  network = {
    name                = module.avm_res_network_virtualnetwork.name
    resource_group_name = azurerm_resource_group.this.name
    node_subnet_id      = module.avm_res_network_virtualnetwork.subnets["subnet"].resource_id
    pod_cidr            = "192.168.0.0/16"
    acr = {
      name                          = module.naming.container_registry.name_unique
      subnet_resource_id            = module.avm_res_network_virtualnetwork.subnets["private_link_subnet"].resource_id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.this.id]
    }
  }
  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.this.id
    ]
  }

  location = var.location # Hardcoded because we have to test in a region with availability zones
  node_pools = {
    workload = {
      name                 = "workloadworkload" #Long name to test the truncate to 12 characters
      vm_size              = var.vm_size
      orchestrator_version = "1.28"
      max_count            = 10
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
      os_disk_size_gb      = 128
    },
    ingress = {
      name                 = "ingress"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      max_count            = 4
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
      os_disk_size_gb      = 128

    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
}

module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  address_space       = var.vnet_address_space #["10.31.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    "subnet" = {
      name             = "nodecidr"
      address_prefixes = ["10.31.0.0/17"]
    }
    "private_link_subnet" = {
      name             = "private_link_subnet"
      address_prefixes = ["10.31.129.0/24"]
    }
  }
}