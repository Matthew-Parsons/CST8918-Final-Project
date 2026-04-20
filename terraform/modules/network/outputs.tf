output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "location" {
  value = azurerm_resource_group.main.location
}

output "test_subnet_id" {
  value = azurerm_subnet.test.id
}

output "prod_subnet_id" {
  value = azurerm_subnet.prod.id
}