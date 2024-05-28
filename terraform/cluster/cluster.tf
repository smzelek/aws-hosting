resource "aws_ecs_cluster" "cluster" {
  name = "cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.autoscaling_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.autoscaling_provider.name
  }
}

resource "aws_ecs_capacity_provider" "autoscaling_provider" {
  name = "autoscaling_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.autoscaling_group.arn
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                = "autoscaling_group"
  min_size            = 0
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  launch_template {
    id      = aws_launch_template.cluster_instance_template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "cluster_instance_template" {
  name_prefix = "cluster_instance"
  # image_id = aws --profile "${AWS_PROFILE}" ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id | jq '.Parameters[0].Value'
  image_id               = "ami-0046cbbe25829d3a8"
  instance_type          = "t4g.small"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  user_data              = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config")

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }
}

data "aws_iam_policy_document" "ec2_instance_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "instance_role_ec2_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "instance_role_ssm_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  role = aws_iam_role.instance_role.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cluster-cpu-alarm"
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
    ClusterName = aws_ecs_cluster.cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "cluster-memory-alarm"
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
    ClusterName = aws_ecs_cluster.cluster.name
  }
}
