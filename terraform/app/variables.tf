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

variable "load_balancer_listener_arn" {
  type = string
}

variable "load_balancer_arn_suffix" {
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

variable "api_domain" {
  type = string
}

variable "email_alert_topic_arn" {
  type = string
}

variable "bootstrap" {
  default = false
  type    = bool
}
