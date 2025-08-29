# ───── AWS & Region ─────
variable "region" {
  description = "AWS region for EKS deployment"
  type        = string
}

# ───── EKS Cluster Config ─────
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of EKS to deploy"
  type        = string
}

# ───── VPC Settings ─────
variable "create_vpc" {
  description = "Set to true to create a new VPC"
  type        = bool
}

variable "vpc_id" {
  description = "Existing VPC ID if create_vpc is false"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to deploy EKS into"
  type        = list(string)
}

# ───── VPC Creation (Optional) ─────
variable "vpc_name" {
  description = "Name of the new VPC (if create_vpc = true)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for new VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones for new VPC"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

# ───── EKS Node Group Settings ─────
variable "node_group_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

# ───── IAM Role Names ─────
variable "cluster_role_name" {
  description = "IAM role name for EKS control plane"
  type        = string
}

variable "node_group_role_name" {
  description = "IAM role name for EKS node group"
  type        = string
}

# ───── App Deployment Config ─────
variable "container_name" {
  description = "Name of the container running the app"
  type        = string
}

variable "container_port" {
  description = "Port that the app container listens on"
  type        = number
}

variable "image_url" {
  description = "ECR image URL (without tag)"
  type        = string
}

variable "image_tag" {
  description = "ECR image tag to deploy"
  type        = string
}
