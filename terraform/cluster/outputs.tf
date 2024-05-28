output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.autoscaling_group.name
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.autoscaling_provider.name
}

# output "load_balancer_listener_arn" {
#   value = aws_alb_listener.alb_listener_http.arn
# }

# output "load_balancer_arn_suffix" {
#   value = aws_alb.default.arn_suffix
# }

# output "load_balancer_domain" {
#   value = aws_alb.default.dns_name
# }

output "service_discovery_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.internal_service_discovery_namespace.id
}

output "vpc_id" {
  value = aws_vpc.default.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "public_subnet_id" {
  value = aws_subnet.public_1.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_sg.id
}

output "rds_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "rds_password" {
  sensitive = true
  value     = aws_secretsmanager_secret_version.db_password.secret_string
}
