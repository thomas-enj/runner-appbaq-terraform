resource "azurerm_subnet" "runner_subnet" {
  name                 = "snet-runner"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "runner_pip" {
  name                = "pip-runner"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "runner_nsg" {
  name                = "nsg-runner"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "runner_nic" {
  name                = "nic-runner"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.runner_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.runner_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "runner_nic_nsg" {
  network_interface_id      = azurerm_network_interface.runner_nic.id
  network_security_group_id = azurerm_network_security_group.runner_nsg.id
}