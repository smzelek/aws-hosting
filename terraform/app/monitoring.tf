resource "aws_cloudwatch_dashboard" "default" {
  dashboard_body = templatefile(
    "${path.module}/dashboard-template.json",
    {
      template_lb           = var.load_balancer_arn_suffix,
      template_asg          = var.autoscaling_group_name,
      template_cluster      = var.cluster_name,
      template_target_group = aws_lb_target_group.target_group.arn_suffix,
      template_service      = aws_ecs_service.service.name,
      template_log_group    = aws_cloudwatch_log_group.default.name,
    }
  )

  dashboard_name = "${var.app_name}-dashboard"
}
