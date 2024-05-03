locals {
  base_cidr = "10.1.0.0/16"
}

resource "aws_vpc" "default" {
  cidr_block           = local.base_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "cluster_vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1d"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 0)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1d"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1c"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 2)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-2"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.default.id
  name   = "lb_sg"

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

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.default.id
  name   = "ecs_sg"
}

resource "aws_security_group_rule" "all_lb_to_ecs" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.lb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "all_ecs_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_alb" "default" {
  name            = "cluster-lb"
  internal        = false
  security_groups = [aws_security_group.lb_sg.id]
  subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_alb_listener" "alb_listener_http" {
  load_balancer_arn = aws_alb.default.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "fixed-response"
    target_group_arn = null

    fixed_response {
      status_code  = 404
      content_type = "application/json"
      message_body = "{\"meta\":{\"status\":404,\"version\":\"dev\"},\"error\":\"Not Found\"}"
    }
  }
}
