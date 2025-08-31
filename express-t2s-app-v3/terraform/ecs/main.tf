provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "t2s_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "t2s_task" {
  family                   = var.task_family
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.cpu
  memory                  = var.memory
  execution_role_arn      = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.image_url}:${var.image_tag}"
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      essential = true
    }
  ])
}

resource "aws_ecs_service" "t2s_service" {
  name            = "t2s-express-service"
  cluster         = aws_ecs_cluster.t2s_cluster.id
  task_definition = aws_ecs_task_definition.t2s_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [var.security_group_id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_cluster.t2s_cluster]
}