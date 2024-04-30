resource "aws_ecs_cluster" "cluster" {
  name = "cluster"
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
  vpc_zone_identifier = [aws_subnet.private_1.id]


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
  # image_id = aws --profile kerukion-admin ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id
  image_id               = "ami-0046cbbe25829d3a8"
  instance_type          = "t4g.small"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.open_internet.id]
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
