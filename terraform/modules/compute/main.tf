terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.8.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.4.1"
    }
  }
}

resource "tls_private_key" "runner_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "runner_vm" {
  name                  = "vm-runner"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = "azureuser"
  network_interface_ids = [var.nic_id]
  tags                  = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.runner_ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "22.04.202608060"
  }
}