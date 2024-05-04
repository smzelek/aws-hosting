terraform {
  backend "s3" {
    bucket = "kerukion-terraform"
    key    = "kerukion-terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  apps = [
    # {
    #   app_name    = "gratzi-io"
    #   github_repo = "smzelek/gratzi.io"
    #   app_domain  = "gratzi.io"
    #   api_domain  = "api-new.gratzi.io"
    #   bootstrap   = false
    # },
    {
      app_name     = "guildvaults-com"
      github_repo  = "smzelek/guildvaults.com"
      app_domain   = "guildvaults.com"
      api_domain   = "api.guildvaults.com"
      subdomain_of = ""
      bootstrap    = false
    },
    {
      app_name     = "tic-metac-toe"
      github_repo  = "smzelek/tic-metac-toe"
      app_domain   = "tic-metac-toe"
      api_domain   = "tic-metac-toe-api"
      subdomain_of = "stevezelek.com"
      bootstrap    = false
    },
    {
      app_name     = "raidtimers-com"
      github_repo  = "smzelek/raidtimers.com"
      app_domain   = "raidtimers.com"
      api_domain   = "api.raidtimers.com"
      subdomain_of = ""
      bootstrap    = false
    },
  ]

  static_apps = [
    {
      app_name     = "stevezelek-com"
      github_repo  = "smzelek/stevezelek.com"
      app_domain   = "stevezelek.com"
      subdomain_of = ""
    },
    {
      app_name     = "pokegrader"
      github_repo  = "smzelek/pokegrader"
      app_domain   = "pokegrader"
      subdomain_of = "stevezelek.com"
    },
    {
      app_name     = "take-me-apart"
      github_repo  = "smzelek/take-me-apart"
      app_domain   = "take-me-apart"
      subdomain_of = "stevezelek.com"
    },
  ]
}

resource "aws_ecr_repository" "default_image" {
  name = "default-image"
}

resource "aws_sns_topic" "email_alerts" {
  # An email Subscription to this SNS Topic must be manually setup in AWS due to Terraform limitations.
  name = "email_alerts"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

module "cluster" {
  source                = "./cluster"
  email_alert_topic_arn = aws_sns_topic.email_alerts.arn
}

module "app" {
  depends_on = [aws_ecr_repository.default_image]
  source     = "./app"
  for_each = {
    for index, app in local.apps :
    app.app_name => app
  }

  # per-app properties
  app_name     = each.value.app_name
  github_repo  = each.value.github_repo
  app_domain   = each.value.app_domain
  bootstrap    = each.value.bootstrap
  api_domain   = each.value.api_domain
  subdomain_of = each.value.subdomain_of

  # universal cluster values
  cluster_arn                = module.cluster.cluster_arn
  cluster_name               = module.cluster.cluster_name
  autoscaling_group_name     = module.cluster.autoscaling_group_name
  vpc_id                     = module.cluster.vpc_id
  load_balancer_listener_arn = module.cluster.load_balancer_listener_arn
  load_balancer_arn_suffix   = module.cluster.load_balancer_arn_suffix
  capacity_provider_name     = module.cluster.capacity_provider_name
  subnet_ids                 = module.cluster.subnet_ids
  ecs_security_group_ids     = module.cluster.ecs_security_group_ids
  email_alert_topic_arn      = aws_sns_topic.email_alerts.arn
}

module "static_app" {
  source = "./static_app"
  for_each = {
    for index, app in local.static_apps :
    app.app_name => app
  }

  app_name     = each.value.app_name
  github_repo  = each.value.github_repo
  app_domain   = each.value.app_domain
  subdomain_of = each.value.subdomain_of
}

data "aws_instances" "asg_instances" {
  instance_tags = {
    AmazonECSManaged = ""
  }
}

output "_1_load_balancer_domain" {
  value = module.cluster.load_balancer_domain
}

output "_2_instance_ids" {
  value = data.aws_instances.asg_instances.ids
}

output "_3_static_app_links" {
  value = {
    for app in local.static_apps : app.app_name => {
      certificate_link  = module.static_app[app.app_name].certificate_link
      cloudfront_domain = module.static_app[app.app_name].cloudfront_domain
    }
  }
}

output "_4_app_links" {
  value = {
    for app in local.apps : app.app_name => {
      certificate_link  = module.app[app.app_name].certificate_link
      secrets_link      = module.app[app.app_name].secrets_link
      cloudfront_domain = module.app[app.app_name].cloudfront_domain
    }
  }
}
