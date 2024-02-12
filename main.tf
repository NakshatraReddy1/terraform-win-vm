terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
}

provider "azurerm" {
    subscription_id = "d8519bc4-73a9-401c-a938-008fd02f46c6"
    tenant_id = "5f46a4e3-1565-4e35-9ca6-7508c03b58d3"
    client_id = "07a153df-6322-4c52-9479-917fa22b0da8"
    client_secret = "nyU8Q~RPbXHkiX5TlFFLzIQPQbT8qTgf5fbr7bRE"
    features {}
  # Configuration options
}

locals {
  resource_group_name = "win-vm"
  location = "UK South"
}

resource "azurerm_resource_group" "vm-rg" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "win-vnet" {
  name                = "win-vnet"
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = ["10.0.0.0/16"]
  depends_on = [
    azurerm_resource_group.vm-rg
    ]
}

resource "azurerm_subnet" "win-subnet" {
  name                 = "win-subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.win-vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [ 
    azurerm_virtual_network.win-vnet
   ]
}

resource "azurerm_network_interface" "win-nic" {
  name                = "win-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.win-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.win-pip.id
  }
  depends_on = [
    azurerm_subnet.win-subnet
    ]
    }
resource "azurerm_public_ip" "win-pip" {
  name                = "win-pip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ 
    azurerm_resource_group.vm-rg
    ]
}

resource "azurerm_network_security_group" "win-nsg" {
  name                = "win-nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "test123"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [
    azurerm_resource_group.vm-rg 
    ]
}

resource "azurerm_subnet_network_security_group_association" "subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.win-subnet.id
  network_security_group_id = azurerm_network_security_group.win-nsg.id
  depends_on = [
    azurerm_subnet.win-subnet,
    azurerm_network_security_group.win-nsg
   ]
}

resource "azurerm_windows_virtual_machine" "demo-win-vm" {
  name                = "demo-win-vm"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  admin_password      = "Azure@123"
  network_interface_ids = [
    azurerm_network_interface.win-nic.id,
  ]

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
  depends_on = [
    azurerm_resource_group.vm-rg,
    azurerm_network_interface.win-nic
    ]
}
















