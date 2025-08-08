terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# CloudWatch Logs for container output (helps debug crashes)
# -----------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 7
}

# -----------------------------
# IAM role for ECS tasks to pull from ECR and write logs
# -----------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = var.task_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = var.task_execution_policy_arn
}

# -----------------------------
# Security group for the service (opens port to the world by default)
# -----------------------------
resource "aws_security_group" "ecs_sg" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  ingress {
    description = "App HTTP"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional: SSH ingress (usually not needed for Fargate)
  # Remove this block if not required.
  # ingress {
  #   description = "SSH"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# ECS Cluster
# -----------------------------
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

# Task Definition pulling image from your ECR URI
resource "aws_ecs_task_definition" "app" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
     cpu_architecture        = "ARM64"   # Change to ARM64 or x86_64 depending on your image
     operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.image_url}:${var.image_tag}"
      essential = true
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])
}

# -----------------------------
# ECS Service (public IP for quick testing)
# -----------------------------
resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_cloudwatch_log_group.ecs
  ]
}

# -----------------------------
# ECS + ALB Integration Scripts
# -----------------------------
# This adds an ALB, target group, listener, and connects it to the ECS service

resource "aws_lb" "ecs_alb" {
  name               = "${var.service_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-security-group"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80  # Replace with your listener port
    to_port     = 80  # Replace with your listener port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from anywhere (adjust as needed for security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "ecs_http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
