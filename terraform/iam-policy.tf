
# Who assumes this? The underlying AWS EC2/Fargate infrastructure.
# What does it do? Pulls Docker images from ECR, decrypts secrets, pushes logs to CloudWatch.

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "enterprise-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = { Name = "ECS-Task-Execution-Role" }
}

# Attach the AWS Managed Policy that contains ECR pull and CloudWatch push permissions
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Who assumes this? The actual Nginx/Application code running INSIDE the container.
# What does it do? Currently nothing. But required to scale if S3/DynamoDB access is needed later.

resource "aws_iam_role" "ecs_task_role" {
  name = "enterprise-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = { Name = "ECS-Task-Role" }
}