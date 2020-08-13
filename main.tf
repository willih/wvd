terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "azurerm" {
  # Allow any 2.x version of the Azure provider
  version = "~> 2.0"
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "WVDLab-Infrastructure" {
  name     = "WVDLab-Infrastructure"
  location = "westus"
}

# Create virtual network
resource "azurerm_virtual_network" "AD-VNet" {
  name                = "AD-VNet"
  address_space       = ["10.10.0.0/16"]
  location            = "westus"
  resource_group_name = azurerm_resource_group.WVDLab-Infrastructure.name
}

# Create subnet
resource "azurerm_subnet" "AD-Subnet" {
  name                 = "AD-Subnet"
  resource_group_name  = azurerm_resource_group.WVDLab-Infrastructure.name
  virtual_network_name = azurerm_virtual_network.AD-VNet.name
  address_prefix       = "10.10.10.0/24"
}

# Create network interface DC01
resource "azurerm_network_interface" "DC01_nic" {
  name                = "DC01_nic"
  location            = "westus"
  resource_group_name = azurerm_resource_group.WVDLab-Infrastructure.name

  ip_configuration {
    name                          = "DC01_nic_conf"
    subnet_id                     = azurerm_subnet.AD-Subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.10.10.11"
  }
}

# Create virtual machine DC01
resource "azurerm_windows_virtual_machine" "DC01" {
  name                  = "DC01"
  location              = "westus"
  resource_group_name   = azurerm_resource_group.WVDLab-Infrastructure.name
  network_interface_ids = [azurerm_network_interface.DC01_nic.id]
  size                  = "Standard_B2ms"
  admin_username      = "ADadmin"
  admin_password      = "Complex.Password"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

}
# Create network interface ADConnect
resource "azurerm_network_interface" "ADConnect_nic" {
  name                = "ADConnect_nic"
  location            = "westus"
  resource_group_name = azurerm_resource_group.WVDLab-Infrastructure.name

  ip_configuration {
    name                          = "ADConnect_nic_conf"
    subnet_id                     = azurerm_subnet.AD-Subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.10.10.15"
    }
}

# Create virtual machine ADConnect
resource "azurerm_windows_virtual_machine" "ADConnect" {
  name                  = "ADConnect"
  location              = "westus"
  resource_group_name   = azurerm_resource_group.WVDLab-Infrastructure.name
  network_interface_ids = [azurerm_network_interface.ADConnect_nic.id]
  size                  = "Standard_B2ms"
  admin_username      = "ADConnectadmin"
  admin_password      = "Complex.Password"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

}

# Create NSG
#resource "azurerm_resource_group" "WVDLab-Infrastructure" {
#  name     = "WVDLab-Infrastructure"
#  location = "West US"
#}

resource "azurerm_network_security_group" "AD-NSG" {
  name                = "AD-NSG"
  location            = azurerm_resource_group.WVDLab-Infrastructure.location
  resource_group_name = azurerm_resource_group.WVDLab-Infrastructure.name
}

resource "azurerm_network_security_rule" "WVDLab-Infrastructure" {
  name                        = "PermitRDP"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "204.9.108.202"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.WVDLab-Infrastructure.name
  network_security_group_name = azurerm_network_security_group.AD-NSG.name
}
