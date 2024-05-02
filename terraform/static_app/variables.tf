locals {
  is_subdomain = var.subdomain_of != ""
  fq_app_name  = local.is_subdomain ? replace("${var.app_name}-${var.subdomain_of}", ".", "-") : var.app_name
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
