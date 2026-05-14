variable "resource_group_location" {
  type        = string
  default     = "polandcentral"
  description = "Location of the resource group"
}
variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix for the resource group name"
}
variable "my_ip_address" {
  type        = string
  description = "My public IP address to allow access to the storage account"
}