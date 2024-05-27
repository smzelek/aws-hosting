terraform {
  backend "s3" {
    bucket = "kerukion-terraform"
    key    = "kerukion-terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "smzelek/aws-hosting/terraform"
    }
  }
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
      bootstrap    = true
    },
    {
      app_name     = "ticmetactoe-com"
      github_repo  = "smzelek/ticmetactoe.com"
      app_domain   = "ticmetactoe.com"
      api_domain   = "api.ticmetactoe.com"
      subdomain_of = ""
      bootstrap    = true
    },
    {
      app_name     = "raidtimers-com"
      github_repo  = "smzelek/raidtimers.com"
      app_domain   = "raidtimers.com"
      api_domain   = "api.raidtimers.com"
      subdomain_of = ""
      bootstrap    = true
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
      app_name     = "pokegrader-com"
      github_repo  = "smzelek/pokegrader.com"
      app_domain   = "pokegrader.com"
      subdomain_of = ""
    },
    {
      app_name     = "takemeapart-com"
      github_repo  = "smzelek/takemeapart.com"
      app_domain   = "takemeapart.com"
      subdomain_of = ""
    },
  ]
}

resource "aws_ecr_repository" "default_image" {
  force_delete = true
  name         = "default-image"
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
  depends_on = [
    aws_ecr_repository.default_image,
    aws_iam_openid_connect_provider.github
  ]
  source = "./app"
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
  subnet_ids                 = module.cluster.private_subnet_ids
  ecs_security_group_ids     = module.cluster.ecs_security_group_ids
  email_alert_topic_arn      = aws_sns_topic.email_alerts.arn
}

module "static_app" {
  depends_on = [
    aws_iam_openid_connect_provider.github
  ]
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

output "_1_app_links" {
  value = {
    for app in local.apps : app.app_name => {
      certificate_link  = module.app[app.app_name].certificate_link
      secrets_link      = module.app[app.app_name].secrets_link
      cloudfront_domain = module.app[app.app_name].cloudfront_domain
    }
  }
}

output "_2_static_app_links" {
  value = {
    for app in local.static_apps : app.app_name => {
      certificate_link  = module.static_app[app.app_name].certificate_link
      cloudfront_domain = module.static_app[app.app_name].cloudfront_domain
    }
  }
}

output "_3_load_balancer_domain" {
  value = module.cluster.load_balancer_domain
}

output "_4_instance_ids" {
  value = data.aws_instances.asg_instances.ids
}

output "_5_rds_endpoint" {
  value = module.cluster.rds_endpoint
}

output "_6_rds_password" {
  value = nonsensitive(module.cluster.rds_password)
}
