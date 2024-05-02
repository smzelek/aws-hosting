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

  dashboard_name = "${local.fq_app_name}-dashboard"
}

resource "aws_cloudwatch_metric_alarm" "crash_alarm" {
  alarm_name          = "${local.fq_app_name}-crash-alarm"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 2

  alarm_actions = [var.email_alert_topic_arn]
  ok_actions    = [var.email_alert_topic_arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix,
    LoadBalancer = var.load_balancer_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${local.fq_app_name}-cpu-alarm"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 5

  alarm_actions = [var.email_alert_topic_arn]
  ok_actions    = [var.email_alert_topic_arn]

  dimensions = {
    ServiceName = aws_ecs_service.service.name
    ClusterName = var.cluster_name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "${local.fq_app_name}-memory-alarm"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 5

  alarm_actions = [var.email_alert_topic_arn]
  ok_actions    = [var.email_alert_topic_arn]

  dimensions = {
    ServiceName = aws_ecs_service.service.name
    ClusterName = var.cluster_name
  }
}
