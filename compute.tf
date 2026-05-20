#create VM1 that is ALLOWED access to the storage account
#Standard_DS1_v2 because there is lack of vCPU in the region (polandcentral) for B1s
resource "azurerm_linux_virtual_machine" "machina1" {
  name                = "machina1-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_DS1_v2"
  admin_username      = "tridudle"

  network_interface_ids = [
    azurerm_network_interface.network_interface_allowed.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 codename is Jammy Jellyfish
    sku       = "22_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "tridudle"
    public_key = file(var.ssh_public_key_path)
  }

}
#create VM2 that is denied access to the storage account
#Standard_DS1_v2 because there is lack of vCPU in the region (polandcentral) for B1s
resource "azurerm_linux_virtual_machine" "machina2" {
  name                = "machina2-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  //fixed after testing pipeline
  size           = "Standard_DS1_v2"
  admin_username = "tridudle"

  network_interface_ids = [
    azurerm_network_interface.network_interface_denied.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "tridudle"
    public_key = file(var.ssh_public_key_path)
  }

}