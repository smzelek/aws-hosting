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
  service_name = local.fq_app_name
}

data "aws_ecs_container_definition" "current_container_definition" {
  count           = var.bootstrap ? 0 : 1
  task_definition = data.aws_ecs_service.current_service[0].task_definition
  container_name  = local.fq_app_name
}

# Manually manage the secret as an env file in AWS Secrets Manager UI
resource "aws_secretsmanager_secret" "secrets" {
  name                    = "${local.fq_app_name}-secrets"
  recovery_window_in_days = 0
}

resource "aws_ecr_repository" "image_repository" {
  name                 = local.fq_app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_cloudwatch_log_group" "default" {
  name              = local.fq_app_name
  retention_in_days = 365
}

# resource "aws_lb_listener_rule" "alb_listener_rule_http" {
#   listener_arn = var.load_balancer_listener_arn

#   action {
#     target_group_arn = aws_lb_target_group.target_group.arn
#     type             = "forward"
#   }

#   condition {
#     host_header {
#       values = [
#         local.is_subdomain ? "${var.api_domain}.${var.subdomain_of}" : var.api_domain
#       ]
#     }
#   }
# }

# resource "aws_lb_target_group" "target_group" {
#   name                 = local.fq_app_name
#   port                 = 80
#   protocol             = "HTTP"
#   target_type          = "instance"
#   vpc_id               = var.vpc_id
#   deregistration_delay = "5"

#   lifecycle {
#     create_before_destroy = true
#   }

#   health_check {
#     matcher             = "200-399"
#     path                = "/elb-status"
#     interval            = "15"
#     healthy_threshold   = "4"
#     unhealthy_threshold = "4"
#     timeout             = "10"
#   }
# }

resource "aws_service_discovery_service" "service_discovery" {
  name         = "_${local.fq_app_name}"
  namespace_id = var.service_discovery_namespace_id

  dns_config {
    namespace_id   = var.service_discovery_namespace_id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 15
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "service" {
  depends_on = [
    aws_service_discovery_service.service_discovery
  ]

  name            = local.fq_app_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2

  service_registries {
    container_name = local.fq_app_name
    container_port = 80
    registry_arn   = aws_service_discovery_service.service_discovery.arn
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.capacity_provider_name
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family             = local.fq_app_name
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  track_latest = true

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }

  container_definitions = jsonencode([
    {
      name      = local.fq_app_name
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
          awslogs-group         = local.fq_app_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
