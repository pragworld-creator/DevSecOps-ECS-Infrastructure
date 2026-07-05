
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { name = "aws_vpc" }
}

resource "aws_subnet" "public_subnet-eu-west-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = { name = "public_subnet-eu-west-1a" }
}

resource "aws_subnet" "private_subnet-eu-west-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"

  tags = { name = "private_subnet-eu-west-1a" }
}

resource "aws_subnet" "public_subnet-eu-west-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = { name = "public_subnet-eu-west-1b" }
}

resource "aws_subnet" "private_subnet-eu-west-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"

  tags = { name = "private_subnet-eu-west-1b" }
}

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.main.id

  tags = { name = "igw_main" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = { name = "nat_eip" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet-eu-west-1a.id

  depends_on = [aws_internet_gateway.igw_main] # First IGW is created before NAT Gateway

  tags = { name = "nat_gw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}

resource "aws_route_table_association" "public_subnet-eu-west-1a_association" {
  subnet_id      = aws_subnet.public_subnet-eu-west-1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet-eu-west-1b_association" {
  subnet_id      = aws_subnet.public_subnet-eu-west-1b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet-eu-west-1a_association" {
  subnet_id      = aws_subnet.private_subnet-eu-west-1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet-eu-west-1b_association" {
  subnet_id      = aws_subnet.private_subnet-eu-west-1b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { name = "alb-front-sg" }
}

resource "aws_security_group" "ecs-tasks-sg" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { name = "ecs-tasks-sg" }
}

resource "aws_security_group" "vpc-endpoint-sg" {
  name        = "vpc-endpoint-sg"
  description = "Allow HTTPS from ECS Tasks to AWS Services via PrivateLink"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs-tasks-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "vpc-endpoint-sg" }
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-west-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]
  tags              = { Name = "S3-Gateway-Endpoint" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-west-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet-eu-west-1a.id, aws_subnet.private_subnet-eu-west-1b.id]
  security_group_ids  = [aws_security_group.vpc-endpoint-sg.id]
  tags                = { Name = "ECR-DKR-Endpoint" }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-west-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet-eu-west-1a.id, aws_subnet.private_subnet-eu-west-1b.id]
  security_group_ids  = [aws_security_group.vpc-endpoint-sg.id]
  tags                = { Name = "ECR-API-Endpoint" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-west-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet-eu-west-1a.id, aws_subnet.private_subnet-eu-west-1b.id]
  security_group_ids  = [aws_security_group.vpc-endpoint-sg.id]
  tags                = { Name = "CloudWatch-Logs-Endpoint" }
}

resource "aws_lb" "alb" {
  name               = "aws-front-facing-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public_subnet-eu-west-1a.id, aws_subnet.public_subnet-eu-west-1b.id]

  tags = { name = "aws-front-facing-alb" }
}

resource "aws_lb_target_group" "ecs-tg" {
  name        = "ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  tags = { name = "ecs-tg" }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"   # The root of your Nginx web server
    matcher             = "200" # Expecting an HTTP 200 OK response
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-tg.arn
  }
}