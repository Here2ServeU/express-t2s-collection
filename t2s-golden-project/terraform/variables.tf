variable "aws_region"      { type = string, default = "us-east-1" }
variable "project_name"    { type = string, default = "t2s-golden" }
variable "cluster_version" { type = string, default = "1.29" }

variable "vpc_cidr"            { type = string,      default = "10.0.0.0/16" }
variable "public_subnet_cidrs" { type = list(string), default = ["10.0.1.0/24","10.0.2.0/24"] }
variable "private_subnet_cidrs"{ type = list(string), default = ["10.0.11.0/24","10.0.12.0/24"] }

variable "node_instance_types" { type = list(string), default = ["t3.medium"] }
variable "node_desired_size"   { type = number,      default = 2 }
variable "node_min_size"       { type = number,      default = 2 }
variable "node_max_size"       { type = number,      default = 4 }

variable "argocd_admin_password" {
  description = "Optional: bcrypt hash for Argo CD admin password"
  type        = string
  default     = ""
  sensitive   = true
}
