#Create Resource Group
resource "azurerm_resource_group" "rg-angelodev" {
  name     = "rg-angelo-dev"
  location = "brazilsouth"
}

#Create Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet-angelodev" {
  name                = "vnet-angelo-dev"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-angelodev.location
  resource_group_name = azurerm_resource_group.rg-angelodev.name
}

#Create subnet on VNet
resource "azurerm_subnet" "sub-angelodev" {
  name                 = "subnet-angelo-dev"
  resource_group_name  = azurerm_resource_group.rg-angelodev.name
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet-angelodev.name
}

#Create Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg-angelodev" {
  name                = "nsg-angelo-dev"
  location            = azurerm_resource_group.rg-angelodev.location
  resource_group_name = azurerm_resource_group.rg-angelodev.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Create Public IP
resource "azurerm_public_ip" "pip-angelodev" {
  name                = "pip-angelo-dev"
  location            = azurerm_resource_group.rg-angelodev.location
  resource_group_name = azurerm_resource_group.rg-angelodev.name
  allocation_method   = "Static"
}

#Create Network Interface
resource "azurerm_network_interface" "nic-angelodev" {
  name                = "nic-angelo-dev"
  location            = azurerm_resource_group.rg-angelodev.location
  resource_group_name = azurerm_resource_group.rg-angelodev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-angelodev.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-angelodev.id
  }
}

#Create Virtual Machine Linux
resource "azurerm_virtual_machine" "vm-angelodev" {
  name                  = "vm-angelo-dev"
  location              = azurerm_resource_group.rg-angelodev.location
  resource_group_name   = azurerm_resource_group.rg-angelodev.name
  network_interface_ids = [azurerm_network_interface.nic-angelodev.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-angelo-dev"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "angelovm"
    admin_username = "adminuser"
    admin_password = "Passwd123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  delete_os_disk_on_termination = true

  tags = {
    environment = "angelodevlab"
  provisioner = "terraform" }
}
