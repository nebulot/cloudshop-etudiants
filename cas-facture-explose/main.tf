terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  default = "westeurope"
}

variable "ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0exemple0cle0publique0factice build-agent"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-catalogue-dev"
  location = var.location
}

# ---------------------------------------------------------------- Réseau
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-catalogue-dev"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  count               = 3
  name                = "pip-catalogue-dev-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-build-agent"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[0].id
  }
}

# ---------------------------------------------------------------- Compute
resource "azurerm_linux_virtual_machine" "build_agent" {
  name                            = "vm-build-agent"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  size                            = "Standard_D16s_v5"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 1024
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "data_old" {
  name                 = "disk-build-cache-old"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 2048
}

resource "azurerm_service_plan" "plan" {
  name                = "asp-catalogue-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P3v3"
  worker_count        = 3
}

resource "azurerm_linux_web_app" "api" {
  name                = "app-catalogue-dev-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = true
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "acrcataloguedev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Premium"
}

# ---------------------------------------------------------------- Données
resource "azurerm_mssql_server" "sql" {
  name                = "sql-catalogue-dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  version             = "12.0"

  azuread_administrator {
    login_username              = "admin@contoso.example"
    object_id                   = "00000000-0000-0000-0000-000000000000"
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "db" {
  name                 = "sqldb-catalogue"
  server_id            = azurerm_mssql_server.sql.id
  sku_name             = "BC_Gen5_8"
  zone_redundant       = true
  max_size_gb          = 500
  storage_account_type = "GeoZone"
}

resource "azurerm_storage_account" "data" {
  name                     = "stcataloguedevdata"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "RAGZRS"
  access_tier              = "Hot"
}

# ---------------------------------------------------------------- Observabilité
resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-catalogue-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 730
}

resource "azurerm_application_insights" "ai" {
  name                = "appi-catalogue-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  retention_in_days   = 730
  sampling_percentage = 100
}
