variable "name" {
  default = "t2s-cluster"
}

variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.145.0.0/16"
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  default = ["10.145.1.0/24", "10.145.2.0/24"]
}

variable "private_subnets" {
  default = ["10.145.3.0/24", "10.145.4.0/24"]
}

variable "intra_subnets" {
  default = ["10.145.5.0/24", "10.145.6.0/24"]
}

variable "tags" {
  default = {
    Example = "t2s-cluster"
  }
}
