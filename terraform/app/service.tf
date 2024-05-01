locals {
  image = var.bootstrap ? "${data.aws_ecr_repository.default_image.repository_url}:latest" : data.aws_ecs_container_definition.current_container_definition[0].image
}

data "aws_ecr_repository" "default_image" {
  name = "default-image"
}

data "aws_region" "current" {}

data "aws_ecs_service" "current_service" {
  count        = var.bootstrap ? 0 : 1
  cluster_arn  = var.cluster_arn
  service_name = var.app_name
}

data "aws_ecs_container_definition" "current_container_definition" {
  count           = var.bootstrap ? 0 : 1
  task_definition = data.aws_ecs_service.current_service[0].task_definition
  container_name  = var.app_name
}

# Manually manage the secret as an env file in AWS Secrets Manager UI
resource "aws_secretsmanager_secret" "secrets" {
  name                    = "${var.app_name}-secrets"
  recovery_window_in_days = 0
}
# Service
resource "aws_ecr_repository" "image_repository" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_cloudwatch_log_group" "default" {
  name              = var.app_name
  retention_in_days = 365
}
resource "aws_alb_listener" "alb_listener_http" {
  load_balancer_arn = var.load_balancer_arn

  port     = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule_http" {
  listener_arn = aws_alb_listener.alb_listener_http.arn

  action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.app_domain]
    }
  }
}

resource "aws_lb_target_group" "target_group" {
  name                 = var.app_name
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = "5"

  health_check {
    matcher             = "200-399"
    path                = "/elb-status"
    interval            = "15"
    healthy_threshold   = "4"
    unhealthy_threshold = "4"
    timeout             = "10"
  }
}

resource "aws_ecs_service" "service" {
  name            = var.app_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.capacity_provider_name
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.app_name
    container_port   = 80
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family             = var.app_name
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  track_latest = true

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = local.image
      memory    = 200
      essential = true
      secrets = [{
        name      = "AWS_SECRETS_STRING",
        valueFrom = aws_secretsmanager_secret.secrets.arn
      }]
      portMappings = [{
        containerPort = 80
      }]
      environment = [{
        name  = "PORT",
        value = "80"
      }],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.app_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
