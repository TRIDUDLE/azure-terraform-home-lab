output "resource_group_name" {
  value       = azurerm_resource_group.example.name
  description = "The name of the resource group"
}
output "website_url" {
  value       = azurerm_storage_account.website.primary_web_endpoint
  description = "The URL of the static website hosted on Azure Storage"
}