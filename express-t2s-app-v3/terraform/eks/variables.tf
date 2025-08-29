variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "prod-cluster"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "env" {
  type        = string
  description = "Environment tag"
  default     = "dev"
}

variable "type" {
  type        = string
  description = "Type tag"
  default     = "Development"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Managed node group instance types"
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type        = number
  default     = 2
}

variable "node_min_size" {
  type        = number
  default     = 1
}

variable "node_max_size" {
  type        = number
  default     = 3
}

variable "vpc_cni_version" {
  type        = string
  description = "AWS VPC CNI addon version (e.g., v1.18.0-eksbuild.1)"
  default     = "v1.18.0-eksbuild.1"
}

variable "kube_proxy_version" {
  type        = string
  description = "Kube-proxy addon version (e.g., v1.27.10-eksbuild.2)"
  default     = "v1.27.10-eksbuild.2"
}
