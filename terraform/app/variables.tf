variable "app_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "load_balancer_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "github_repo" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "app_frontend_domain" {
  type = string
}

variable "bootstrap" {
  default = false
  type    = bool
}
