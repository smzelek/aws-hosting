resource "aws_instance" "haproxy" {
  ami                         = "ami-0046cbbe25829d3a8"
  instance_type               = "t4g.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.haproxy_sg.id]
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.haproxy_instance_profile.name

  tags = {
    Name = "haproxy"
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

data "aws_iam_policy_document" "haproxy_instance_policy_document" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.haproxy_config.arn
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.haproxy_config.arn}/*"
    ]
  }
  statement {
    actions = [
      "route53:ListHostedZones",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "ecs:DescribeServices",
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "access_config_bucket" {
  policy = data.aws_iam_policy_document.haproxy_instance_policy_document.json
}

resource "aws_iam_role" "haproxy_instance_role" {
  name               = "haproxy-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "haproxy_instance_role_ssm_policy_attachment" {
  role       = aws_iam_role.haproxy_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "haproxy_instance_role_cloudwatch_policy_attachment" {
  role       = aws_iam_role.haproxy_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "access_config_bucket_attachment" {
  role       = aws_iam_role.haproxy_instance_role.name
  policy_arn = aws_iam_policy.access_config_bucket.arn
}

resource "aws_iam_instance_profile" "haproxy_instance_profile" {
  role = aws_iam_role.haproxy_instance_role.name
}

resource "aws_security_group" "haproxy_sg" {
  vpc_id = var.vpc_id
  name   = "haproxy_sg"

  ingress {
    description = "Insecure inbound traffic."
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Secure inbound traffic."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outgoing traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "all_haproxy_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.haproxy_sg.id
  security_group_id        = var.ecs_security_group_id
}

resource "aws_s3_bucket" "haproxy_config" {
  bucket = "kerukion-haproxy-config"
}

resource "aws_cloudwatch_log_group" "haproxy" {
  name              = "haproxy"
  retention_in_days = 365
}

resource "aws_eip" "haproxy_ip" {
  instance = aws_instance.haproxy.id
}
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "haproxy-cpu-alarm"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 5
  alarm_actions       = [var.email_alert_topic_arn]
  ok_actions          = [var.email_alert_topic_arn]
  dimensions = {
    InstanceId = aws_instance.haproxy.id
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name = "haproxy-memory-alarm"

  metric_query {
    id          = "m1"
    metric {
      namespace   = "TelegrafMetrics"
      metric_name = "memory_utilization_total"
      stat        = "Average"
      period      = 60

      dimensions = {
        instance_id = aws_instance.haproxy.id
      }
    }
  }
  metric_query {
    id          = "m2"
    metric {
      namespace   = "TelegrafMetrics"
      metric_name = "memory_utilization_used"
      stat        = "Average"
      period      = 60

      dimensions = {
        instance_id = aws_instance.haproxy.id
      }
    }
  }
  metric_query {
    label       = "MemoryUtilization"
    expression  = "100*(m2/m1)"
    id          = "e1"
    return_data = true
  }

  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  evaluation_periods  = 5
  treat_missing_data  = "breaching"
  datapoints_to_alarm = 5

  alarm_actions = [var.email_alert_topic_arn]
  ok_actions    = [var.email_alert_topic_arn]
}
