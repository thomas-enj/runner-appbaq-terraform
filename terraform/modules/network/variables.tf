variable "resource_group_name" {
  type        = string
  description = "Name of the existing or to-be-created resource group"
}

variable "location" {
  type        = string
  description = "Azure region for the resources"
}

variable "vnet_name" {
  type        = string
  description = "Name of the parent virtual network"
}

variable "admin_ip" {
  type        = string
  description = "Personal/Corporate public IP address (format x.x.x.x/32) for initial SSH access"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the Azure network resources"
}