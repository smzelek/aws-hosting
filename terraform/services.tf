module "gratzi_io_api" {
  depends_on = [aws_ecr_repository.default_image]
  source     = "./service"

  app_name               = "gratzi-io-api"
  cluster_arn            = aws_ecs_cluster.cluster.arn
  vpc_id                 = aws_vpc.default.id
  load_balancer_arn      = aws_alb.default.arn
  capacity_provider_name = aws_ecs_capacity_provider.autoscaling_provider.name
  subnet_ids             = [aws_subnet.private_1.id]
  security_group_ids     = [aws_security_group.open_internet.id]
  github_repo            = "smzelek/gratzi.io"
  app_domain             = "gratzi.io"
  bootstrap              = false
}
