# Common Names
project_name = "sqlag"
environment_name         = "p" # p- production, t- test, d- dev, s- staging

# Location Names
primary_location_name       = "Central US"
secondary_location_name     = "East US" # For secondary region

# Resource Names
primary_resource_group_name = "rg-primary"
secondary_resource_group_name = "rg-secondry"

primary_vnet_name = "vnet-primary"
secondary_vnet_name = "vnet-secondry"

# Vnet Peering Names
primary_vnet_peering_name = "vnet-peering-primary"
secondary_vnet_peering_name = "vnet-peering-secondry"

# Network Security Group Names
primary_nsg_name = "nsg-primary"
secondary_nsg_name = "nsg-secondry"

# SQL Server VM Names
primary_sql_server_vm_name = "sqlvm-primary"
primary_sql_server_vm_nic_name = "sqlvm-nic-primary"
primary_sql_server_vm_public_ip_name = "sqlvm-pip-primary"

secondary_sql_server_vm_name = "sqlvm-secondry"
secondary_sql_server_vm_nic_name = "sqlvm-nic-secondry"
secondary_sql_server_vm_public_ip_name = "sqlvm-pip-secondry"

application_vm_name = "applicationvm"
application_vm_nic_name = "applicationvm-nic"
application_vm_public_ip_name = "applicationvm-pip"

domaincontroller_vm_name = "localad"
domaincontroller_vm_nic_name = "localad-nic"
domaincontroller_vm_public_ip_name = "localad-pip"
