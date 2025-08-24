variable "region" {
  description = "AWS region"
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
  description = "ECS Task family"
  type        = string
}

variable "task_cpu" {
  description = "Fargate CPU units"
  type        = string
}

variable "task_memory" {
  description = "Fargate memory MiB"
  type        = string
}

variable "container_name" {
  description = "Container name in task"
  type        = string
}

variable "container_port" {
  description = "App port exposed by container"
  type        = number
}

variable "desired_count" {
  description = "Number of tasks"
  type        = number
}

variable "image_url" {
  description = "ECR repo URI without tag"
  type        = string
}

variable "image_tag" {
  description = "Image tag"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for ALB/ECS"
  type        = list(string)
}

variable "sg_name" {
  description = "ECS SG name"
  type        = string
}

variable "sg_description" {
  description = "ECS SG description"
  type        = string
}

variable "task_execution_role_name" {
  description = "Execution role name"
  type        = string
}

variable "task_execution_policy_arn" {
  description = "Execution role policy ARN"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

variable "cpu_arch" {
  description = "CPU architecture for task: ARM64 or X86_64"
  type        = string
  default     = "X86_64"
}

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
  default     = null
}

variable "target_group_name" {
  description = "Name for the target group"
  type        = string
  default     = null
}
