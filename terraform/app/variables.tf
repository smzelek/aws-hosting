locals {
  is_subdomain = var.subdomain_of != ""
  fq_app_name  = local.is_subdomain ? replace("${var.app_name}-${var.subdomain_of}", ".", "-") : var.app_name
}

variable "app_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "autoscaling_group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "service_discovery_namespace_id" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "api_domain" {
  type = string
}

variable "subdomain_of" {
  type = string
}

variable "email_alert_topic_arn" {
  type = string
}

variable "bootstrap" {
  default = false
  type    = bool
}
