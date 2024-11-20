resource "aws_cloudwatch_dashboard" "default" {
  dashboard_body = templatefile(
    "${path.module}/dashboard-template.json",
    {
      template_asg                 = var.autoscaling_group_name,
      template_cluster             = var.cluster_name,
      template_service             = aws_ecs_service.service.name,
      template_log_group           = aws_cloudwatch_log_group.service.name,
      template_haproxy_instance_id = var.haproxy_instance_id
    }
  )

  dashboard_name = "${local.fq_app_name}-dashboard"
}

resource "aws_cloudwatch_metric_alarm" "crash_alarm" {
  alarm_name          = "${local.fq_app_name}-crash-alarm"
  namespace           = "TelegrafMetrics"
  metric_name         = "service_task_status_gauge"
  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 1

  alarm_actions = [var.email_alert_topic_arn]
  ok_actions    = [var.email_alert_topic_arn]

  dimensions = {
    service = local.fq_app_name
    state   = "down"
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
