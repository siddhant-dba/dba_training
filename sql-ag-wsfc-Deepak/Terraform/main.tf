# Resource Group
resource "azurerm_resource_group" "resourceGroupPrimary" {
  name     = "${var.primary_resource_group_name}${local.prefixName}-001"
  location = var.primary_location_name
}

resource "azurerm_resource_group" "resourceGroupSecondary" {
  name     = "${var.secondary_resource_group_name}${local.prefixName}-001"
  location = var.secondary_location_name
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg_primary" {
  name                = var.primary_nsg_name
  location            = var.primary_location_name
  resource_group_name = azurerm_resource_group.resourceGroupPrimary.name
  security_rule {
    name                       = "Inbound3389Allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_secondary" {
  name                = var.secondary_nsg_name
  location            = var.secondary_location_name
  resource_group_name = azurerm_resource_group.resourceGroupSecondary.name
  security_rule {
    name                       = "Inbound3389Allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Virtual Networks
resource "azurerm_virtual_network" "vNetPrimary" {
  name                = "${var.primary_vnet_name}${local.prefixName}-001"
  location            = var.primary_location_name
  resource_group_name = azurerm_resource_group.resourceGroupPrimary.name
  address_space       = ["10.165.1.0/27"]

  subnet {
    name           = "default"
    address_prefix = "10.165.1.0/27"
    security_group = azurerm_network_security_group.nsg_primary.id
  }

  depends_on = [azurerm_resource_group.resourceGroupPrimary]
}

resource "azurerm_virtual_network" "vNetSecondary" {
  name                = "${var.secondary_vnet_name}${local.prefixName}-001"
  location            = var.secondary_location_name
  resource_group_name = azurerm_resource_group.resourceGroupSecondary.name
  address_space       = ["10.165.2.0/27"]

  subnet {
    name           = "default"
    address_prefix = "10.165.2.0/27"
    security_group = azurerm_network_security_group.nsg_secondary.id
  }

  depends_on = [azurerm_resource_group.resourceGroupSecondary]
}

# Virtual Network Peering
resource "azurerm_virtual_network_peering" "vnet_peering_primary" {
  name                         = var.primary_vnet_peering_name
  resource_group_name          = azurerm_resource_group.resourceGroupPrimary.name
  virtual_network_name         = azurerm_virtual_network.vNetPrimary.name
  remote_virtual_network_id    = azurerm_virtual_network.vNetSecondary.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "vnet_peering_secondary" {
  name                         = var.secondary_vnet_peering_name
  resource_group_name          = azurerm_resource_group.resourceGroupSecondary.name
  virtual_network_name         = azurerm_virtual_network.vNetSecondary.name
  remote_virtual_network_id    = azurerm_virtual_network.vNetPrimary.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
}

# Virtual Machines
# The following modules are used to create the virtual machines for SQL Server, Application Server, and Domain Controller.
module "primary_sql_server" {
  source                           = "./VirtualMachine"
  server_vm_name                   = var.primary_sql_server_vm_name
  server_vm_nic_name               = var.primary_sql_server_vm_nic_name
  server_vm_public_ip_name         = var.primary_sql_server_vm_public_ip_name
  location_name                    = var.primary_location_name
  resource_group_name              = azurerm_resource_group.resourceGroupPrimary.name
  subnet_id                        = one(azurerm_virtual_network.vNetPrimary.subnet).id
  source_image_reference_publisher = "MicrosoftSQLServer"
  source_image_reference_offer     = "SQL2016SP2-WS2016"
  source_image_reference_sku       = "Enterprise"
  depends_on                       = [azurerm_virtual_network.vNetPrimary]
}

module "secondary_sql_server" {
  source                           = "./VirtualMachine"
  server_vm_name                   = var.secondary_sql_server_vm_name
  server_vm_nic_name               = var.secondary_sql_server_vm_nic_name
  server_vm_public_ip_name         = var.secondary_sql_server_vm_public_ip_name
  location_name                    = var.secondary_location_name
  resource_group_name              = azurerm_resource_group.resourceGroupSecondary.name
  subnet_id                        = one(azurerm_virtual_network.vNetSecondary.subnet).id
  source_image_reference_publisher = "MicrosoftSQLServer"
  source_image_reference_offer     = "SQL2016SP2-WS2016"
  source_image_reference_sku       = "Enterprise"
  depends_on                       = [azurerm_virtual_network.vNetSecondary]
}

module "application_server" {
  source                           = "./VirtualMachine"
  server_vm_name                   = var.application_vm_name
  server_vm_nic_name               = var.application_vm_nic_name
  server_vm_public_ip_name         = var.application_vm_public_ip_name
  location_name                    = var.primary_location_name
  resource_group_name              = azurerm_resource_group.resourceGroupPrimary.name
  subnet_id                        = one(azurerm_virtual_network.vNetPrimary.subnet).id
  source_image_reference_publisher = "MicrosoftSQLServer"
  #source_image_reference_offer     = "sql2022-ws2022"
  source_image_reference_offer     = "SQL2016SP2-WS2016"
  source_image_reference_sku       = "Enterprise"
  depends_on                       = [azurerm_virtual_network.vNetPrimary]
}

module "domain_controller" {
  source                           = "./VirtualMachine"
  server_vm_name                   = var.domaincontroller_vm_name
  server_vm_nic_name               = var.domaincontroller_vm_nic_name
  server_vm_public_ip_name         = var.domaincontroller_vm_public_ip_name
  location_name                    = var.primary_location_name
  resource_group_name              = azurerm_resource_group.resourceGroupPrimary.name
  subnet_id                        = one(azurerm_virtual_network.vNetPrimary.subnet).id
  source_image_reference_publisher = "MicrosoftWindowsServer"
  source_image_reference_offer     = "WindowsServer"
  source_image_reference_sku       = "2022-Datacenter"
  depends_on                       = [azurerm_virtual_network.vNetPrimary]
}
