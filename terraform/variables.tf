variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  default     = "francecentral"
  description = "Azure region for the resources"
}

variable "vnet_name" {
  type        = string
  default     = "vnet-runner"
  description = "Name of the parent virtual network"
}

variable "admin_ip" {
  type        = string
  description = "Personal/Corporate public IP address (format x.x.x.x/32) for initial SSH access"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Size of the Virtual Machine"
}

variable "owner" {
  type        = string
  description = "Owner of the Azure resources"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags, overriding the default tags when keys match"
}