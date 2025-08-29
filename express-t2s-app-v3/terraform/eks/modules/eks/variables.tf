variable "cluster_name"              { type = string }
variable "cluster_version"           { type = string }
variable "subnet_ids_private"        { type = list(string) }
variable "cluster_security_group_id" { type = string }
variable "cluster_role_arn"          { type = string }
variable "node_role_arn"             { type = string }

variable "desired_size"   { type = number }
variable "min_size"       { type = number }
variable "max_size"       { type = number }
variable "instance_types" { type = list(string) }

variable "vpc_cni_version"    { type = string }
variable "kube_proxy_version" { type = string }
