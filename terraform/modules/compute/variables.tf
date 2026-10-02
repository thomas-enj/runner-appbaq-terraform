variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region for the resources"
}

variable "nic_id" {
  type        = string
  description = "Network Interface ID from the network module"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Size of the Virtual Machine"
}