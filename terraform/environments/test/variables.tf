variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "Canada Central"
}

variable "weather_api_key" {
  type      = string
  sensitive = true
}

variable "image_tag" {
  type    = string
  default = "latest"
}