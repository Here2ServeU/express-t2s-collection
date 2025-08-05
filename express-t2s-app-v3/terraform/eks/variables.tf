variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "t2s-eks-cluster"
}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

