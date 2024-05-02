locals {
  is_subdomain = var.subdomain_of != ""
}

variable "app_name" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "subdomain_of" {
  type = string
}
