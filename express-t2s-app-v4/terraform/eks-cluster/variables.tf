variable "name" {
  description = "Cluster (and VPC) name"
  type        = string
  default     = "t2s-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.145.0.0/16"
}

variable "azs" {
  description = "Two AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.145.1.0/24", "10.145.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.145.3.0/24", "10.145.4.0/24"]
}

variable "kubernetes_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "express-webapp-v3"
  }
}
