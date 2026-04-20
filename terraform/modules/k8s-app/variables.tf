variable "namespace" {
  type = string
}

variable "image" {
  type = string
}

variable "weather_api_key" {
  type      = string
  sensitive = true
}

variable "redis_host" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "redis_password" {
  type      = string
  sensitive = true
}