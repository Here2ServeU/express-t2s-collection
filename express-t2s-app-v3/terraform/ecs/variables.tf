variable "region" {}
variable "repo_name" {}
variable "cluster_name" {}
variable "task_execution_role_name" {}
variable "task_execution_policy_arn" {
  default = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
variable "sg_name" {}
variable "sg_description" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "task_family" {}
variable "task_cpu" {}
variable "task_memory" {}
variable "container_name" {}
variable "service_name" {}
variable "desired_count" {}
