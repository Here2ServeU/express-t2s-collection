# ─────────────────────────────────────────────
# Terraform Input Variables (EKS Deployment)
# ─────────────────────────────────────────────

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "create_vpc" {
  description = "Toggle to create a new VPC or use existing one"
  type        = bool
}

# ───────────── VPC Configuration ─────────────

variable "vpc_name" {
  description = "Name of the VPC to be created (if create_vpc is true)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
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

# ───── Use Existing VPC/Subnets (Optional) ─────

variable "vpc_id" {
  description = "ID of existing VPC (required if create_vpc is false)"
  type        = string
}

variable "subnet_ids" {
  description = "List of existing subnet IDs (required if create_vpc is false)"
  type        = list(string)
}

# ───────────── EKS & App Configuration ─────────────

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of EKS cluster (e.g., 1.29)"
  type        = string
}

variable "image_url" {
  description = "ECR image URL (without tag)"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to use (e.g., latest)"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
}
