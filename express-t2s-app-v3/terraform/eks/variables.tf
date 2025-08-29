variable "cluster_name"        { type = string }
variable "region"              { type = string  default = "us-east-1" }
variable "vpc_cidr"            { type = string  default = "10.0.0.0/16" }

variable "env"  { type = string  default = "Prod" }
variable "type" { type = string  default = "Production" }

# Node group sizes
variable "node_desired_size"  { type = number default = 2 }
variable "node_min_size"      { type = number default = 2 }
variable "node_max_size"      { type = number default = 4 }
variable "node_instance_types"{ type = list(string) default = ["t3.medium"] }

# EKS addons versions (optional)
variable "vpc_cni_version"    { type = string default = "v1.18.0-eksbuild.1" }
variable "kube_proxy_version" { type = string default = "v1.29.0-eksbuild.1" }
variable "cluster_version"    { type = string default = "1.29" }
