locals {
  apps = [
    {
      app_name               = "gratzi-io"
      cluster_arn            = aws_ecs_cluster.cluster.arn
      vpc_id                 = aws_vpc.default.id
      load_balancer_arn      = aws_alb.default.arn
      capacity_provider_name = aws_ecs_capacity_provider.autoscaling_provider.name
      subnet_ids             = [aws_subnet.private_1.id]
      security_group_ids     = [aws_security_group.open_internet.id]
      github_repo            = "smzelek/gratzi.io"
      app_domain             = "gratzi.io"
      app_frontend_domain    = "new.gratzi.io"
      bootstrap              = false
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

  app_name               = each.value.app_name
  cluster_arn            = each.value.cluster_arn
  vpc_id                 = each.value.vpc_id
  load_balancer_arn      = each.value.load_balancer_arn
  capacity_provider_name = each.value.capacity_provider_name
  subnet_ids             = each.value.subnet_ids
  security_group_ids     = each.value.security_group_ids
  github_repo            = each.value.github_repo
  app_domain             = each.value.app_domain
  app_frontend_domain    = each.value.app_frontend_domain
  bootstrap              = each.value.bootstrap
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

