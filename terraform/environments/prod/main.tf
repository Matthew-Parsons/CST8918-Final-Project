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
      version = "~> 2.30"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = "cst8918-final-project-group-8"
  location            = var.location
}

module "aks" {
  source              = "../../modules/aks"
  cluster_name        = "cst8918-prod-aks"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location
  subnet_id           = module.network.prod_subnet_id
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 3
}

module "acr" {
  source              = "../../modules/acr"
  name                = "cst8918acr8jm26"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location
}

module "redis" {
  source              = "../../modules/redis"
  name                = "cst8918-prod-redis-8jm26"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = module.aks.kubelet_object_id
  role_definition_name = "AcrPull"
  scope                = module.acr.id
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
  image           = "${module.acr.login_server}/weather-app:${var.image_tag}"
  weather_api_key = var.weather_api_key
  redis_host      = module.redis.hostname
  redis_port      = module.redis.ssl_port
  redis_password  = module.redis.primary_access_key

  depends_on = [azurerm_role_assignment.acr_pull]
}