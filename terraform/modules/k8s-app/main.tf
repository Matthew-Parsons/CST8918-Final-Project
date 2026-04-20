resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "weather-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    WEATHER_API_KEY = var.weather_api_key
    REDIS_HOST      = var.redis_host
    REDIS_PORT      = tostring(var.redis_port)
    REDIS_PASSWORD  = var.redis_password
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "weather-app"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "weather-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weather-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-app"
        }
      }

      spec {
        container {
          name  = "weather-app"
          image = var.image

          port {
            container_port = 3000
          }

          env {
            name = "WEATHER_API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "WEATHER_API_KEY"
              }
            }
          }

          env {
            name = "REDIS_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "REDIS_HOST"
              }
            }
          }

          env {
            name = "REDIS_PORT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "REDIS_PORT"
              }
            }
          }

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "REDIS_PASSWORD"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "weather-app-service"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "weather-app"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}