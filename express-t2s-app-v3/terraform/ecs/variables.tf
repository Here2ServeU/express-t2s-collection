variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "container_image" {
  description = "The container image to run (e.g., ECR URL or dockerhub image)"
  type        = string
}

variable "container_port" {
  description = "Port the container application listens on"
  type        = number
}

variable "task_cpu" {
  description = "Fargate task CPU units (1 vCPU = 1024)"
  type        = number
}

variable "task_memory" {
  description = "Fargate task memory (in MiB)"
  type        = number
}

variable "desired_count" {
  description = "Number of docker containers to run"
  type        = number
}
