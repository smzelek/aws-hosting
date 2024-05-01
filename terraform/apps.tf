locals {
  apps = [
    {
      app_name            = "gratzi-io"
      github_repo         = "smzelek/gratzi.io"
      app_domain          = "gratzi.io"
      app_frontend_domain = "new.gratzi.io"
      bootstrap           = false
    },
  ]
}

module "app" {
  depends_on = [aws_ecr_repository.default_image]
  source     = "./app"
  for_each = {
    for index, app in local.apps :
    app.app_name => app
  }

  # per-app properties
  app_name            = each.value.app_name
  github_repo         = each.value.github_repo
  app_domain          = each.value.app_domain
  app_frontend_domain = each.value.app_frontend_domain
  bootstrap           = each.value.bootstrap

  # universal cluster values
  cluster_arn              = aws_ecs_cluster.cluster.arn
  cluster_name             = aws_ecs_cluster.cluster.name
  autoscaling_group_name   = aws_autoscaling_group.autoscaling_group.name
  vpc_id                   = aws_vpc.default.id
  load_balancer_arn        = aws_alb.default.arn
  load_balancer_arn_suffix = aws_alb.default.arn_suffix
  capacity_provider_name   = aws_ecs_capacity_provider.autoscaling_provider.name
  subnet_ids               = [aws_subnet.private_1.id]
  security_group_ids       = [aws_security_group.open_internet.id]
}

output "app_links" {
  value = {
    for app in local.apps : app.app_name => {
      certificate_link  = module.app[app.app_name].certificate_link
      secrets_link      = module.app[app.app_name].secrets_link
      cloudfront_domain = module.app[app.app_name].cloudfront_domain
    }
  }
}

output "load_balancer_domain" {
  value = aws_alb.default.dns_name
}

