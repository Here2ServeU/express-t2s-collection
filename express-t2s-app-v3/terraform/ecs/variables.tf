# ===== Core =====
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
  description = "Fargate CPU units (e.g., 256, 512, 1024)"
  type        = string
}

variable "task_memory" {
  description = "Fargate memory in MiB (e.g., 512, 1024, 2048)"
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

# ===== Image (ECR) =====
variable "image_url" {
  description = "ECR repository URI without tag (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo)"
  type        = string
}

variable "image_tag" {
  description = "Image tag (e.g., latest)"
  type        = string
}

# ===== Networking =====
variable "vpc_id" {
  description = "VPC ID where the service runs"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service (prefer two in different AZs)"
  type        = list(string)
}

# ===== Security Group =====
variable "sg_name" {
  description = "Security group name"
  type        = string
}

variable "sg_description" {
  description = "Security group description"
  type        = string
}

# ===== IAM =====
variable "task_execution_role_name" {
  description = "Name for the ECS task execution role"
  type        = string
}

variable "task_execution_policy_arn" {
  description = "Managed policy for ECS task execution role"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ===== ALB =====
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "alb_internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "alb_listener_port" {
  description = "ALB listener port (80 for HTTP)"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

variable "target_group_name" {
  description = "Name of the target group used by the ALB"
  type        = string
}

# Optional TLS (set both to enable HTTPS listener)
variable "enable_https" {
  description = "Enable HTTPS (443) listener if true"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (required if enable_https = true)"
  type        = string
  default     = ""
}
