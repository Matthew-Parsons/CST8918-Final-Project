resource "azurerm_resource_group" "backend" {
  name     = "cst8918-tf-rg"
  location = var.location
}

resource "azurerm_storage_account" "backend" {
  name                     = "cst8918tfstorage123"
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.backend.id
  container_access_type = "private"
}