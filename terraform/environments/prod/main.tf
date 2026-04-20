terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name  = "cst8918-tf-rg"
    storage_account_name = "cst8918tfstg808"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "main" {
  name = "cst8918-final-project-group-8"
}

data "azurerm_virtual_network" "main" {
  name                = "cst8918-vnet"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "prod" {
  name                 = "cst8918-prod-subnet"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_container_registry" "acr" {
  name                = "cst8918acr8jm26"
  resource_group_name = data.azurerm_resource_group.main.name
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = "cst8918-prod-aks"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.prod.id
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 3
}

module "redis" {
  source              = "../../modules/redis"
  name                = "cst8918-prod-redis"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = module.aks.kubelet_object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.acr.id
}

provider "kubernetes" {
  host                   = yamldecode(module.aks.kube_config).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(module.aks.kube_config).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.aks.kube_config).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.aks.kube_config).clusters[0].cluster.certificate-authority-data)
}

module "app" {
  source          = "../../modules/k8s-app"
  namespace       = "weather"
  image           = "${data.azurerm_container_registry.acr.login_server}/weather-app:${var.image_tag}"
  weather_api_key = var.weather_api_key
  redis_host      = module.redis.hostname
  redis_port      = module.redis.ssl_port
  redis_password  = module.redis.primary_access_key

  depends_on = [azurerm_role_assignment.acr_pull]
}