variable "region" {
  description = "AWS region to deploy to"
  type        = string
}

variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "service_name" {
  description = "ECS Service name"
  type        = string
}

variable "task_family" {
  description = "ECS Task family name"
  type        = string
}

variable "task_cpu" {
  description = "Fargate CPU units (e.g., 256, 512)"
  type        = string
}

variable "task_memory" {
  description = "Fargate memory in MiB (e.g., 512, 1024)"
  type        = string
}

variable "container_name" {
  description = "Container name inside the task"
  type        = string
}

variable "container_port" {
  description = "Application port exposed by the container"
  type        = number
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
}

variable "image_url" {
  description = "ECR repository URI without tag"
  type        = string
}

variable "image_tag" {
  description = "Image tag (e.g., latest)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the service runs"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service (prefer two in different AZs)"
  type        = list(string)
}

variable "sg_name" {
  description = "Security group name"
  type        = string
}

variable "sg_description" {
  description = "Security group description"
  type        = string
}

variable "task_execution_role_name" {
  description = "Name for the ECS task execution role"
  type        = string
}

variable "task_execution_policy_arn" {
  description = "Managed policy for ECS task execution role"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
