terraform {
  required_version = ">= 1.16.4, < 1.17.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.8.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.4.1"
    }
  }
}

provider "azurerm" {
  features {}
  resource_providers_to_register = ["Microsoft.Compute", "Microsoft.Network"]
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "network" {
  source              = "./network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = azurerm_virtual_network.vnet.name
  admin_ip            = var.admin_ip
}

module "compute" {
  source              = "./compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  nic_id              = module.network.nic_id
  vm_size             = var.vm_size
}