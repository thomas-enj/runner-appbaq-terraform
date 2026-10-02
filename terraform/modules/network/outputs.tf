output "nic_id" {
  value       = azurerm_network_interface.runner_nic.id
  description = "ID of the network interface to pass to the compute module"
}

output "public_ip_address" {
  value       = azurerm_public_ip.runner_pip.ip_address
  description = "Public IP address of the runner VM"
}