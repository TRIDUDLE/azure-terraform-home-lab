# Create a random name for the resource group using random_pet
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix

  # Use an empty separator because website names cannot contain hyphens or underscores
  separator = ""
}

# Create a resource group using the generated random name
resource "azurerm_resource_group" "example" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

#create virtual network and subnet for the storage account
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_pet.rg_name.id}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet for the virtual machine1
resource "azurerm_subnet" "vm1_subnet" {
  name                 = "subnet-allowed-${random_pet.rg_name.id}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.12.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}
# Create a subnet for the virtual machine2
resource "azurerm_subnet" "vm2_subnet" {
  name                 = "subnet-denied-${random_pet.rg_name.id}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.24.0/24"]
}


# create two virtual machines, one in each subnet. The VM in the first subnet (vm1_subnet) will be able to access the storage account, while the VM in the second subnet (vm2_subnet) will be denied access due to the network rules we will set up later.

# create public ip for the first VM
# allowed VM
resource "azurerm_public_ip" "public_ip_allowed" {
  name                = "pip-allowed-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

}
# Create a network interface for the virtual machine and associate it with the subnet and public IP
# allowed VM
resource "azurerm_network_interface" "network_interface_allowed" {
  name                = "nic-allowed-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_allowed.id
  }
}

#create public ip for the second VM
# denied VM
resource "azurerm_public_ip" "public_ip_denied" {
  name                = "pip-denied-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
}
# Create a network interface for the virtual machine and associate it with the subnet and public IP
# denied VM
resource "azurerm_network_interface" "network_interface_denied" {
  name                = "nic-denied-${random_pet.rg_name.id}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm2_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_denied.id
  }
}


# Create an Azure Storage account within the resource group
resource "azurerm_storage_account" "website" {
  name                     = "st${random_pet.rg_name.id}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "lab"
    project     = "terraform-learning"
  }
}

# create network rules for the storage account 
# By default, the storage account will deny all traffic. 
# We will allow traffic from first subnet (vm1_subnet - 10.0.24.0) and from my current IP address 
#(var.my_ip_address) to access the storage account.
resource "azurerm_storage_account_network_rules" "security_rules" {
  storage_account_id = azurerm_storage_account.website.id

  # Default action is to deny all traffic
  default_action = "Deny"

  # Whitelist specific IP addresses and subnets
  ip_rules                   = [var.my_ip_address]
  virtual_network_subnet_ids = [azurerm_subnet.vm1_subnet.id]
  bypass                     = ["Metrics"]
}



#Create a static website configuration for the storage account
resource "azurerm_storage_account_static_website" "website_config" {
  storage_account_id = azurerm_storage_account.website.id
  index_document     = "index.html"
}

# add a simple html file to web container
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.website.name
  storage_container_name = "$web"
  type                   = "Block"
  source_content         = "<html><body><h1>Welcome to static testing page!</h1></body></html>"
  content_type           = "text/html"

  # ran into an error creating blob, so to overcome it, I'm adding an explicit dependency:
  # explicitly depends on the static website configuration to ensure it is created before the blob
  depends_on = [azurerm_storage_account_static_website.website_config]
}

