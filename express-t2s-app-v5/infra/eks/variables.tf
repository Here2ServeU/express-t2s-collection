variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Cluster/base name"
  type        = string
  default     = "t2s-eks"
}

variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "164.45.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnets"
  type        = list(string)
  default     = ["164.45.0.0/20", "164.45.16.0/20"]
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
  default     = ["164.45.32.0/20", "164.45.48.0/20"]
}

variable "enable_ingress" {
  description = "Install ingress-nginx"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {
    Project = "express-t2s"
    Env     = "dev"
  }
}
