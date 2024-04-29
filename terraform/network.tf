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
  availability_zone       = "us-east-1c"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 0)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.default.id
  availability_zone       = "us-east-1d"
  cidr_block              = cidrsubnet(local.base_cidr, 8, 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-2"
  }
}

# resource "aws_vpn_gateway" "vpn" {
#   vpc_id = aws_vpc.default.id
# }

# resource "aws_eip" "nat" {
#   vpc        = true
#   depends_on = [aws_internet_gateway.default]
# }

# resource "aws_nat_gateway" "gw" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public_1.id

#   depends_on = [aws_internet_gateway.default]
# }

# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.default.id
#   availability_zone = "us-east-1d"
#   cidr_block        = "10.1.128.0/24"
#   tags = {
#     Name = "private"
#   }
# }

# resource "aws_route_table" "private" {
#   vpc_id           = aws_vpc.default.id
#   propagating_vgws = [aws_vpn_gateway.vpn.id]
# }

# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.gw.id
# }

# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }

resource "aws_security_group" "open_internet" {
  vpc_id = aws_vpc.default.id
  name   = "open_internet"

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

resource "aws_alb" "default" {
  name            = "cluster-lb"
  internal        = false
  security_groups = [aws_security_group.open_internet.id]
  subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}
