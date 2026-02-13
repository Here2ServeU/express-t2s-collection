variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "express-t2s-app"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_image" {
  description = "The container image to run"
  type        = string
  default     = "730335276920.dkr.ecr.us-east-1.amazonaws.com/express-t2s-app-repo:latest" # Replace with your ECR URL
}

variable "container_port" {
  description = "Port the container application listens on"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "Fargate task CPU units (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory (in MiB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 2
}
