# General Settings
aws_region      = "us-east-1"
app_name        = "express-t2s-app"
environment     = "dev"

# Network Settings
vpc_cidr        = "10.0.0.0/16"

# Application Settings
container_port  = 3000
desired_count   = 2

# Container Image (Replace with your ECR URL if needed)
container_image = "nginx:latest" 

# Fargate Resource Sizing
# 256 CPU = 0.25 vCPU
# 512 MiB = 0.5 GB RAM
task_cpu        = 256
task_memory     = 512
