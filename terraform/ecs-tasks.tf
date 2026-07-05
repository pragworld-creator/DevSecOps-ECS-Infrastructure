
# Fargate is serverless, by any chance if a container crashes, you can't SSH into a host to read logs.
# We must route logs to CloudWatch.
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/enterprise-portfolio"
  retention_in_days = 7 # Automatically delete logs after 7 days to save costs

  tags = {
    Name = "Enterprise-Portfolio-Logs"
  }
}

# The ECS Cluster (The Logical Boundary)
resource "aws_ecs_cluster" "main" {
  name = "enterprise-portfolio-cluster"

  # Enable Container Insights for granular CPU/Memory/Network matrices
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "Enterprise-Portfolio-Cluster"
  }
}

# The Task Definition (The Blueprint)
resource "aws_ecs_task_definition" "app" {
  family                   = "enterprise-portfolio-task"
  network_mode             = "awsvpc" # used for Fargate
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  # The Container Definition (JSON Array)
  container_definitions = jsonencode([
    {
      name = "portfolio-container"
      # ECR Image url
      image     = "121154744538.dkr.ecr.eu-west-1.amazonaws.com/enterprise-portfolio:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "eu-west-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# The ECS Service (The Orchestrator)
resource "aws_ecs_service" "app_service" {
  name            = "enterprise-portfolio-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Wait for the ALB Listener to exist BEFORE starting containers, 
  # otherwise the target group health checks will fail immediately.
  depends_on = [aws_lb_listener.alb_listener]

  network_configuration {
    # Placing tasks in the Private Vault subnets
    subnets = [aws_subnet.private_subnet-eu-west-1a.id, aws_subnet.private_subnet-eu-west-1b.id]

    # Attach the ECS Security Group (Chained to the ALB)
    security_groups = [aws_security_group.ecs-tasks-sg.id]

    # CRITICAL SECURITY MEASURE: Ensure no public IP is assigned to the container.
    # It must communicate through NAT Gateway or VPC Endpoints.
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-tg.arn
    container_name   = "portfolio-container"
    container_port   = 80
  }
}