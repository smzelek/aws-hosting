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
  map_public_ip_on_launch = false
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1d"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 1)
  map_public_ip_on_launch = false
  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1c"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 3)
  map_public_ip_on_launch = false
  tags = {
    Name = "private-2"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.default.id
  name   = "db_sg"
}

resource "aws_security_group_rule" "all_ecs_to_db" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ecs_sg.id
  security_group_id        = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "all_db_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_sg.id
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.default.id
  name   = "ecs_sg"
}

resource "aws_security_group_rule" "all_ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_service_discovery_private_dns_namespace" "internal_service_discovery_namespace" {
  name        = "internal"
  vpc         = aws_vpc.default.id
}
