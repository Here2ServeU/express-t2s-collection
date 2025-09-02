variable "aws_region" {
  description = "AWS region for the provider and resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "t2s-eks"
}

variable "kubernetes_version" {
  description = "EKS control plane version (e.g., 1.30)"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.145.0.0/16"
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs (same count/order as azs)"
  type        = list(string)
  default     = ["10.145.1.0/24", "10.145.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs (same count/order as azs)"
  type        = list(string)
  default     = ["10.145.3.0/24", "10.145.4.0/24"]
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = { Project = "t2s-eks" }
}

variable "admin_ip" {
  description = "Your workstation’s public IP for EKS API access"
  type        = string
  default = "66.115.215.172"
}

variable "admin_ip_override" {
  description = "Optional manual admin public IP to allow to the EKS API."
  type        = string
  default     = ""
}
